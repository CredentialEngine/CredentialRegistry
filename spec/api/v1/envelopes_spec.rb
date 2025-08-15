require_relative 'shared_examples/signed_endpoint'
require_relative '../../support/shared_contexts/envelopes_with_url'

RSpec.describe API::V1::Envelopes do
  let(:auth_token) { create(:user).auth_token.value }
  let!(:envelopes) { create_list(:envelope, 2) }

  before { create(:envelope_community, name: 'ce_registry') }

  context 'GET /:community/community' do # rubocop:todo RSpec/ContextWording
    before { get '/learning-registry/community' }

    it { expect_status(:ok) }

    it 'retrieves the metadata community' do
      expect_json(name: 'learning_registry')
    end
  end

  context 'GET /:community/envelopes' do # rubocop:todo RSpec/ContextWording
    context 'public community' do # rubocop:todo RSpec/ContextWording
      let(:metadata_only) { false }

      before do
        get "/learning-registry/envelopes?metadata_only=#{metadata_only}"
      end

      it { expect_status(:ok) }

      it 'retrieves all the envelopes ordered by date' do # rubocop:todo RSpec/ExampleLength
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

      # rubocop:todo RSpec/NestedGroups
      context 'providing a different metadata community' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'only retrieves envelopes from the provided community' do
          create(:envelope, :from_cer)

          get '/ce-registry/envelopes'

          expect_json_sizes(1)
          expect_json('0.envelope_community', 'ce_registry')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'metadata only' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:metadata_only) { true }

        it "returns only envelopes' metadata" do
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelopes.last.envelope_id)
          expect_json('0.resource', nil)
          expect_json('0.decoded_resource', nil)
        end
      end
    end

    context 'secured community' do # rubocop:todo RSpec/ContextWording
      let(:api_key) { Faker::Lorem.characters }
      let(:cer) { EnvelopeCommunity.find_by(name: 'ce_registry') }
      let(:lr) { EnvelopeCommunity.find_by(name: 'learning_registry') }

      before do
        EnvelopeCommunity.update_all(secured: true)

        # rubocop:todo RSpec/MessageSpies
        expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          .with(api_key, lr)
          .at_least(:once)
          .and_return(api_key_validation_result)

        get '/learning-registry/envelopes',
            'Authorization' => "Token #{api_key}"
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

        # rubocop:todo RSpec/NestedGroups
        context 'providing a different metadata community' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            # rubocop:todo RSpec/MessageSpies
            expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
              # rubocop:enable RSpec/MessageSpies
              .with(api_key, cer)
              .at_least(:once)
              .and_return(api_key_validation_result)
          end

          it 'only retrieves envelopes from the provided community' do
            create(:envelope, :from_cer)

            get '/ce-registry/envelopes', 'Authorization' => "Token #{api_key}"

            expect_json_sizes(1)
            expect_json('0.envelope_community', 'ce_registry')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups

        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'GET /:community/envelopes/downloads/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:finished_at) { nil }
    let(:internal_error_message) { nil }
    let(:started_at) { nil }

    let(:envelope_download) do
      create(
        :envelope_download,
        finished_at:,
        internal_error_message:,
        started_at:
      )
    end

    let(:perform_request) do
      get "/envelopes/downloads/#{envelope_download.id}",
          'Authorization' => "Token #{auth_token}"
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'all good' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        perform_request
        expect_status(:ok)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'in progress' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:started_at) { Time.current }

        it 'returns `in progress`' do
          expect_json('status', 'in progress')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'failed' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:finished_at) { Time.current }
        let(:internal_error_message) { Faker::Lorem.sentence }

        it 'returns `failed`' do
          expect_json('status', 'failed')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'finished' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:finished_at) { Time.current }

        it 'returns `finished` and URL' do
          expect_json('status', 'finished')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'pending' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns `pending`' do
          expect_json('status', 'pending')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'POST /:community/envelopes' do # rubocop:todo RSpec/ContextWording
    let(:now) { Faker::Time.forward(days: 7).in_time_zone('UTC') }
    let(:organization) { create(:organization) }
    let(:publishing_organization) { create(:organization) }

    it_behaves_like 'a signed endpoint', :post

    context 'with valid parameters' do # rubocop:todo RSpec/MultipleMemoizedHelpers
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
        expect { publish.call }.to change(Envelope, :count).by(1)

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
        expect_json(last_verified_on: now.to_date.to_s)
        expect_json(node_headers: { updated_at: now.utc.as_json })
        expect_json(owned_by: organization._ctid)
        expect_json(published_by: publishing_organization._ctid)
      end

      it 'honors the metadata community' do
        post '/ce-registry/envelopes',
             attributes_for(:envelope, :from_cer)

        expect_json(envelope_community: 'ce_registry')
      end

      it "indexes the envelope's resources" do
        # rubocop:todo RSpec/MessageSpies
        expect(ExtractEnvelopeResourcesJob).to receive(:perform_later)
          # rubocop:enable RSpec/MessageSpies
          .with(created_envelope_id)

        post '/ce-registry/envelopes', attributes_for(:envelope, :from_cer)
      end
    end

    context 'update_if_exists parameter is set to true' do # rubocop:todo RSpec/ContextWording
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'learning-registry' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

        # rubocop:todo RSpec/NestedGroups
        context 'without changes' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
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
            last_verified_on = envelope.last_verified_on
            updated_at = envelope.updated_at
            envelope.reload

            expect(envelope.envelope_version).to eq('0.52.0')
            expect_json(changed: false)
            expect_json(node_headers: { updated_at: updated_at.change(usec: 0).utc.as_json })
            expect_json(owned_by: organization._ctid)
            expect_json(last_verified_on: last_verified_on.to_s)
            expect_json(published_by: publishing_organization._ctid)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with changes' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
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
            expect_json(last_verified_on: now.to_date.to_s)
            expect_json(node_headers: { updated_at: now.utc.as_json })
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'ce_registry' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id) { '05de35b5-8820-497f-bf4e-b4fa0c2107dd' }
        let!(:envelope) do
          create(:envelope, :from_cer, envelope_id: id)
        end

        # rubocop:todo RSpec/NestedGroups
        context 'without changes' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
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
            last_verified_on = envelope.last_verified_on
            updated_at = envelope.updated_at
            envelope.reload

            expect(envelope.envelope_version).to eq('0.52.0')
            expect_json(changed: false)
            expect_json(last_verified_on: last_verified_on.to_s)
            expect_json(node_headers: { updated_at: updated_at.change(usec: 0).utc.as_json })
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with changes' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
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

          it 'silently updates the record' do # rubocop:todo RSpec/ExampleLength
            envelope.reload

            expect(envelope.envelope_version).to eq('0.53.0')
            expect(envelope.organization).to eq(organization)
            expect(envelope.publishing_organization).to eq(
              publishing_organization
            )

            expect_json(changed: true)
            expect_json(node_headers: { updated_at: now.utc.as_json })
            expect_json(last_verified_on: now.to_date.to_s)
            expect_json(owned_by: organization._ctid)
            expect_json(published_by: publishing_organization._ctid)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    context 'when persistence error' do
      before do
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

    context 'with paradata' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:publish) do
        lambda do
          travel_to now do
            post '/learning-registry/envelopes', attributes_for(:envelope, :paradata)
          end
        end
      end

      it 'returns a 201 Created http status code' do
        publish.call
        expect_status(:created)
      end

      it 'creates a new envelope' do
        expect { publish.call }.to change(Envelope, :count).by(1)
      end

      it 'returns the newly created envelope' do
        publish.call

        expect_json_types(envelope_id: :string)
        expect_json(envelope_type: 'paradata')
      end
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'empty envelope_id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:publish) do
        lambda do
          post '/ce-registry/envelopes', attributes_for(
            :envelope, :from_cer, envelope_id: ''
          )
        end
      end

      it 'consider envelope_id as non existent' do
        expect(Envelope.where(envelope_id: '')).to be_empty
        expect { publish.call }.to change(Envelope, :count).by(1)
        expect_status(:created)
        expect(Envelope.where(envelope_id: '')).to be_empty
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  context 'POST /:community/envelopes/downloads' do # rubocop:todo RSpec/ContextWording
    let(:perform_request) do
      post '/envelopes/downloads',
           nil,
           'Authorization' => "Token #{auth_token}"
    end

    context 'invalid token' do # rubocop:todo RSpec/ContextWording
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end

    context 'all good' do # rubocop:todo RSpec/ContextWording
      # rubocop:todo RSpec/MultipleExpectations
      it 'starts download' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          perform_request
        end.to change(EnvelopeDownload, :count).by(1)

        envelope_download = EnvelopeDownload.last
        expect(envelope_download.envelope_community.name).to eq('ce_registry')

        expect_status(:created)
        expect_json('id', envelope_download.id)

        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)

        enqueued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
        expect(enqueued_job[:args]).to eq([envelope_download.id])
        expect(enqueued_job[:job]).to eq(DownloadEnvelopesJob)
      end
    end
  end

  context 'PUT /:community/envelopes' do # rubocop:todo RSpec/ContextWording
    include_context 'envelopes with url'

    it_behaves_like 'a signed endpoint', :put

    context 'with valid parameters' do
      before do
        put '/learning-registry/envelopes',
            attributes_for(:delete_envelope)
      end

      it { expect_status(:no_content) }
    end

    context 'trying to delete a non existent envelope' do # rubocop:todo RSpec/ContextWording
      before do
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

    context 'providing a different metadata community' do # rubocop:todo RSpec/ContextWording
      before do
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
