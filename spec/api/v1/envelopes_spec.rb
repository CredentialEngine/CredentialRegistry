require_relative 'shared_examples/signed_endpoint'
require_relative '../../support/shared_contexts/envelopes_with_url'

RSpec.describe API::V1::Envelopes do
  before(:each) { create(:envelope_community, name: 'ce_registry') }
  let!(:envelopes) { [create(:envelope), create(:envelope)] }

  context 'GET /:community/community' do
    before(:each) { get '/learning-registry/community' }

    it { expect_status(:ok) }

    it 'retrieves the metadata community' do
      expect_json(name: 'learning_registry')
    end
  end

  context 'GET /:community/envelopes' do
    context 'public community' do
      let(:metadata_only) { false }

      before do
        get "/learning-registry/envelopes?metadata_only=#{metadata_only}"
      end

      it { expect_status(:ok) }

      it 'retrieves all the envelopes ordered by date' do
        expect_json_sizes(2)
        expect_json('0.envelope_id', envelopes.last.envelope_id)
        expect_json('0.resource', envelopes.last.resource)
        expect_json(
          '0.decoded_resource',
          **envelopes
            .last
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
      end

      it 'presents the JWT fields in decoded form' do
        expect_json('0.decoded_resource.name', 'The Constitution at Work')
      end

      it 'returns the public key from the key pair used to sign the resource' do
        expect_json_keys('*', :resource_public_key)
      end

      context 'providing a different metadata community' do
        it 'only retrieves envelopes from the provided community' do
          create(:envelope, :from_cer)

          get '/ce-registry/envelopes'

          expect_json_sizes(1)
          expect_json('0.envelope_community', 'ce_registry')
        end
      end

      context 'metadata only' do
        let(:metadata_only) { true }

        it "returns only envelopes' metadata" do
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelopes.last.envelope_id)
          expect_json('0.resource', nil)
          expect_json('0.decoded_resource', nil)
        end
      end
    end

    context 'secured community' do
      let(:api_key) { Faker::Lorem.characters }

      before do
        EnvelopeCommunity.update_all(secured: true)

        expect(ValidateApiKey).to receive(:call)
          .with(api_key)
          .at_least(1).times
          .and_return(api_key_validation_result)
      end

      before do
        get '/learning-registry/envelopes',
            'Authorization' => "Token #{api_key}"
      end

      context 'authenticated' do
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }

        it 'retrieves all the envelopes ordered by date' do
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelopes.last.envelope_id)
        end

        it 'presents the JWT fields in decoded form' do
          expect_json('0.decoded_resource.name', 'The Constitution at Work')
        end

        it 'returns the public key from the key pair used to sign the resource' do
          expect_json_keys('*', :resource_public_key)
        end

        context 'providing a different metadata community' do
          it 'only retrieves envelopes from the provided community' do
            create(:envelope, :from_cer)

            get '/ce-registry/envelopes', 'Authorization' => "Token #{api_key}"

            expect_json_sizes(1)
            expect_json('0.envelope_community', 'ce_registry')
          end
        end
      end

      context 'unauthenticated' do
        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
    end
  end

  context 'GET /:community/envelopes/download' do
    let(:auth_token) { create(:user).auth_token.value }

    let(:perform_request) do
      get '/envelopes/download', 'Authorization' => "Token #{auth_token}"
    end

    context 'invalid token' do
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end

    context 'all good' do
      let!(:envelope1) do
        create(:envelope, :from_cer)
      end

      let!(:envelope2) do
        create(:envelope, :from_cer, :with_cer_credential)
      end

      it 'downloads zipped resources' do
        perform_request
        expect_status(:ok)
        expect(response.content_type).to eq('application/zip')

        entries = {}

        Zip::InputStream.open(StringIO.new(response.body)) do |stream|
          loop do
            entry = stream.get_next_entry
            break unless entry

            entries[entry.name] = JSON(stream.read)
          end
        end

        expect(entries).to eq(
          "#{envelope1.envelope_ceterms_ctid}.json" => envelope1.processed_resource,
          "#{envelope2.envelope_ceterms_ctid}.json" => envelope2.processed_resource
        )
      end
    end
  end

  context 'POST /:community/envelopes' do
    let(:now) { Faker::Time.forward(days: 7) }
    let(:organization) { create(:organization) }
    let(:publishing_organization) { create(:organization) }

    it_behaves_like 'a signed endpoint', :post

    context 'with valid parameters' do
      let(:created_envelope_id) { Envelope.maximum(:id).to_i + 1 }

      let(:publish) do
        lambda do
          travel_to now do
            post '/learning-registry/envelopes?' \
                 "owned_by=#{organization._ctid}&" \
                 "published_by=#{publishing_organization._ctid}",
                 attributes_for(:envelope)
          end
        end
      end

      it 'returns a 201 Created http status code' do
        publish.call

        expect_status(:created)
      end

      it 'creates a new envelope' do
        expect { publish.call }.to change { Envelope.count }.by(1)

        envelope = Envelope.last
        expect(envelope.organization).to eq(organization)
        expect(envelope.publishing_organization).to eq(publishing_organization)
      end

      it 'returns the newly created envelope' do
        publish.call

        expect_json_types(envelope_id: :string)
        expect_json(changed: true)
        expect_json(envelope_community: 'learning_registry')
        expect_json(envelope_version: '0.52.0')
        expect_json(node_headers: { updated_at: now.utc.to_s })
        expect_json(owned_by: organization._ctid)
        expect_json(published_by: publishing_organization._ctid)
      end

      it 'honors the metadata community' do
        post '/ce-registry/envelopes',
             attributes_for(:envelope, :from_cer)

        expect_json(envelope_community: 'ce_registry')
      end

      it "indexes the envelope's resources" do
        expect(ExtractEnvelopeResourcesJob).to receive(:perform_later)
          .with(created_envelope_id)

        post '/ce-registry/envelopes', attributes_for(:envelope, :from_cer)
      end
    end

    context 'update_if_exists parameter is set to true' do
      context 'learning-registry' do
        let(:id) { '05de35b5-8820-497f-bf4e-b4fa0c2107dd' }
        let!(:envelope) do
          create(
            :envelope,
            envelope_ceterms_ctid: nil,
            envelope_id: id,
            organization: organization,
            publishing_organization: publishing_organization
          )
        end

        context 'without changes' do
          before(:each) do
            travel_to now do
              post '/learning-registry/envelopes?update_if_exists=true&' \
                   "owned_by=#{organization._ctid}&" \
                   "published_by=#{publishing_organization._ctid}",
                   attributes_for(:envelope,
                                  envelope_ceterms_ctid: nil,
                                  envelope_id: id)
            end
          end

          it { expect_status(:ok) }

          it "doesn't update the record" do
            updated_at = envelope.updated_at
            envelope.reload

            expect(envelope.envelope_version).to eq('0.52.0')
            expect_json(changed: false)
            expect_json(node_headers: { updated_at: updated_at.utc.to_s })
            expect_json(owned_by: organization._ctid)
            expect_json(published_by: publishing_organization._ctid)
          end
        end

        context 'with changes' do
          before(:each) do
            travel_to now do
              post '/learning-registry/envelopes?update_if_exists=true',
                   attributes_for(:envelope,
                                  envelope_id: id,
                                  envelope_version: '0.53.0')
            end
          end

          it { expect_status(:ok) }

          it 'silently updates the record' do
            envelope.reload

            expect(envelope.envelope_version).to eq('0.53.0')
            expect_json(changed: true)
            expect_json(node_headers: { updated_at: now.utc.to_s })
          end
        end
      end

      context 'ce_registry' do
        let(:id) { '05de35b5-8820-497f-bf4e-b4fa0c2107dd' }
        let!(:envelope) do
          create(:envelope, :from_cer, envelope_id: id)
        end

        context 'without changes' do
          before(:each) do
            travel_to now do
              post '/ce-registry/envelopes?update_if_exists=true',
                   attributes_for(:envelope,
                                  :from_cer,
                                  envelope_ceterms_ctid: envelope.envelope_ceterms_ctid,
                                  envelope_id: id,
                                  resource: envelope.resource)
            end
          end

          it { expect_status(:ok) }

          it "doesn't update the record" do
            updated_at = envelope.updated_at
            envelope.reload

            expect(envelope.envelope_version).to eq('0.52.0')
            expect_json(changed: false)
            expect_json(node_headers: { updated_at: updated_at.utc.to_s })
          end
        end

        context 'with changes' do
          before do
            travel_to now do
              post '/ce-registry/envelopes?update_if_exists=true&' \
                   "owned_by=#{organization._ctid}&" \
                   "published_by=#{publishing_organization._ctid}",
                   attributes_for(:envelope,
                                  :from_cer,
                                  envelope_id: id,
                                  envelope_version: '0.53.0')
              end
          end

          it { expect_status(:ok) }

          it 'silently updates the record' do
            envelope.reload

            expect(envelope.envelope_version).to eq('0.53.0')
            expect(envelope.organization).to eq(organization)
            expect(envelope.publishing_organization).to eq(
              publishing_organization
            )

            expect_json(changed: true)
            expect_json(node_headers: { updated_at: now.utc.to_s })
            expect_json(owned_by: organization._ctid)
            expect_json(published_by: publishing_organization._ctid)
          end
        end
      end
    end

    context 'with invalid parameters' do
      before(:each) { post '/learning-registry/envelopes', {} }
      let(:errors) { json_body[:errors] }

      it { expect_status(:unprocessable_entity) }

      it 'returns the list of validation errors' do
        expect(errors).to_not be_empty
        expect(errors).to include('envelope_type : is required')
      end

      it 'returns the corresponding json-schemas' do
        expect_json_keys(:json_schema)
        expect_json('json_schema.0', %r{schemas/envelope})
      end
    end

    context 'when persistence error' do
      before(:each) do
        create(:envelope, :with_id)
        post '/ce-registry/envelopes',
             attributes_for(:envelope,
                            :from_cer,
                            :with_cer_credential,
                            envelope_id: 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56')
      end

      it { expect_status(:unprocessable_entity) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Envelope has already been taken')
      end
    end

    context 'when encoded resource has validation errors' do
      context 'learning-registry' do
        before(:each) do
          post '/learning-registry/envelopes', attributes_for(
            :envelope,
            envelope_community: 'learning_registry',
            resource: jwt_encode(url: 'something.com')
          )
        end

        it { expect_status(:unprocessable_entity) }

        it 'returns the list of validation errors' do
          expect_json_keys(:errors)
          expect_json('errors.0', 'name : is required')
        end

        it 'returns the corresponding json-schemas' do
          expect_json_keys(:json_schema)
          expect_json('json_schema.0', %r{schemas/envelope})
          expect_json('json_schema.1', %r{schemas/learning_registry})
        end
      end

      context 'ce-registry' do
        before(:each) do
          post '/ce-registry/envelopes', attributes_for(
            :envelope,
            :from_cer,
            resource: jwt_encode('@type': 'ceterms:Credential')
          )
        end

        it { expect_status(:unprocessable_entity) }

        it 'returns the list of validation errors' do
          expect_json_keys(:errors)
          expect_json('errors.0', 'ceterms:ctid : is required')
        end

        it 'returns the corresponding json-schemas' do
          expect_json_keys(:json_schema)
          expect_json('json_schema.0', %r{schemas/envelope})
          expect_json('json_schema.1', %r{ce_registry/credential})
        end
      end

      context 'ce_registry requires a valid @type for validation config' do
        it 'requires a @type' do
          post '/ce-registry/envelopes', attributes_for(
            :envelope, :from_cer, resource: jwt_encode({})
          )
          expect_status(400)

          expect_json_keys(:errors)
          expect_json('errors.0', '@type is required')
        end

        it 'ensures the @type value must be valid' do
          post '/ce-registry/envelopes', attributes_for(
            :envelope, :from_cer, resource: jwt_encode('@type' => 'wrongType')
          )
          expect_status(400)

          expect_json_keys(:errors)
          expect_json('errors.0', 'Cannot load json-schema. '\
            'The property \'@type\' has an invalid value \'wrongType\'')
        end
      end
    end

    context 'with invalid json-ld' do
      before(:each) do
        post '/learning-registry/envelopes', { '@context': 42 }.to_json,
             'Content-Type' => 'application/json'
      end

      it { expect_status(:unprocessable_entity) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', '@context : did not match one or more .*')
      end

      it 'returns the corresponding json-schemas' do
        expect_json_keys(:json_schema)
        expect_json('json_schema.1', %r{schemas/json_ld})
      end
    end

    context 'with paradata' do
      let(:publish) do
        lambda do
          post '/learning-registry/envelopes',
               attributes_for(:envelope, :paradata)
        end
      end

      it 'returns a 201 Created http status code' do
        publish.call
        expect_status(:created)
      end

      it 'creates a new envelope' do
        expect { publish.call }.to change { Envelope.count }.by(1)
      end

      it 'returns the newly created envelope' do
        publish.call

        expect_json_types(envelope_id: :string)
        expect_json(envelope_type: 'paradata')
      end
    end

    context 'empty envelope_id' do
      let(:publish) do
        lambda do
          post '/ce-registry/envelopes', attributes_for(
            :envelope, :from_cer, envelope_id: ''
          )
        end
      end

      it 'consider envelope_id as non existent' do
        expect(Envelope.where(envelope_id: '')).to be_empty
        expect { publish.call }.to change { Envelope.count }.by(1)
        expect_status(:created)
        expect(Envelope.where(envelope_id: '')).to be_empty
      end
    end

    context 'skip_validation' do
      context 'config enabled' do
        it 'skips resource validation when skip_validation=true is provided' do
          # ce/registry has skip_validation enabled
          post '/ce-registry/envelopes', attributes_for(
            :envelope, :from_cer,
            resource: jwt_encode('@type' => 'ceterms:Badge')
          )
          expect_status(:unprocessable_entity)
          expect_json_keys(:errors)
          expect_json('errors.0', /ceterms:ctid : is required/)

          expect do
            post '/ce-registry/envelopes?skip_validation=true',
                 attributes_for(
                   :envelope,
                   :from_cer,
                   resource: jwt_encode('@type' => 'ceterms:Badge')
                 )
          end.to change { Envelope.count }.by(1)
          expect_status(:created)
        end
      end

      context 'config disabled' do
        it 'does not skip validation even if the flag is provided' do
          # learning_registry does not have skip_validation enabled
          post '/learning-registry/envelopes?skip_validation=true',
               attributes_for(:envelope, :with_invalid_resource)
          expect_status(:unprocessable_entity)
          expect_json_keys(:errors)
          expect_json('errors.0', /name : is required/)
        end
      end
    end
  end

  context 'PUT /:community/envelopes' do
    include_context 'envelopes with url'

    it_behaves_like 'a signed endpoint', :put

    context 'with valid parameters' do
      before(:each) do
        put '/learning-registry/envelopes',
            attributes_for(:delete_envelope)
      end

      it { expect_status(:no_content) }
    end

    context 'with invalid parameters' do
      before(:each) do
        put '/learning-registry/envelopes',
            attributes_for(:delete_envelope).merge(delete_token_format: 'nope')
      end

      it { expect_status(:unprocessable_entity) }
      it { expect_json('errors.0', /delete_token_format : Must be one of .*/) }
    end

    context 'trying to delete a non existent envelope' do
      before(:each) do
        put '/learning-registry/envelopes',
            attributes_for(:delete_envelope).merge(
              envelope_id: 'non-existent-resource'
            )
      end

      it { expect_status(:not_found) }

      it 'returns the list of validation errors' do
        expect_json('errors.0', 'No matching envelopes found')
      end

      it 'returns the corresponding json-schema' do
        expect_json_keys(:json_schema)
        expect_json('json_schema.0', %r{schemas/delete_envelope})
      end
    end

    context 'providing a different metadata community' do
      before(:each) do
        put '/ce-registry/envelopes',
            attributes_for(:delete_envelope)
      end

      it { expect_status(:not_found) }

      it 'does not find envelopes outside its community' do
        expect_json('errors.0', 'No matching envelopes found')
      end
    end
  end
end
