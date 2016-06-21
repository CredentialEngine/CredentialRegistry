require_relative 'shared_examples/signed_endpoint'
require_relative '../../support/shared_contexts/envelopes_with_url'

describe API::V1::Envelopes do
  before(:each) { create(:envelope_community, name: 'credential_registry') }
  let!(:envelopes) { [create(:envelope), create(:envelope)] }

  context 'GET /api/envelopes' do
    before(:each) { get '/api/envelopes' }

    it { expect_status(:ok) }

    it 'retrieves all the envelopes ordered by date' do
      expect_json_sizes(2)
      expect_json('0.envelope_id', envelopes.last.envelope_id)
    end

    it 'presents the JWT fields in decoded form' do
      expect_json('0.decoded_resource.name', 'The Constitution at Work')
    end

    context 'providing a different metadata community' do
      it 'only retrieves envelopes from the provided community' do
        create(:envelope, :from_credential_registry)

        get '/api/credential-registry/envelopes'

        expect_json_sizes(1)
        expect_json('0.envelope_community', 'credential_registry')
      end
    end
  end

  context 'POST /api/envelopes' do
    it_behaves_like 'a signed endpoint', :post

    context 'with valid parameters' do
      let(:publish) do
        -> { post '/api/envelopes', attributes_for(:envelope, :with_id) }
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
        expect_json(envelope_community: 'learning_registry')
        expect_json(envelope_version: '0.52.0')
      end

      it 'honors the metadata community if specified' do
        post '/api/credential-registry/envelopes',
             attributes_for(:envelope, :from_credential_registry)

        expect_json(envelope_community: 'credential_registry')
      end
    end

    context 'update_if_exists parameter is set to true' do
      let(:id) { '05de35b5-8820-497f-bf4e-b4fa0c2107dd' }
      let!(:envelope) { create(:envelope, envelope_id: id) }

      before(:each) do
        post '/api/envelopes?update_if_exists=true',
             attributes_for(:envelope,
                            envelope_id: id,
                            envelope_version: '0.53.0')
      end

      it { expect_status(:ok) }

      it 'silently updates the record' do
        envelope.reload

        expect(envelope.envelope_version).to eq('0.53.0')
      end
    end

    context 'with invalid parameters' do
      before(:each) { post '/api/envelopes', {} }
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
        post '/api/envelopes',
             attributes_for(:envelope,
                            envelope_id: 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56')
      end

      it { expect_status(:unprocessable_entity) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Envelope has already been taken')
      end
    end

    context 'when encoded resource has validation errors' do
      before(:each) do
        post '/api/envelopes', attributes_for(
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

    context 'with invalid json-ld' do
      before(:each) do
        post '/api/envelopes', { '@context': 42 }.to_json,
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
  end

  context 'DELETE /api/envelopes' do
    include_context 'envelopes with url'

    it_behaves_like 'a signed endpoint', :delete,
                    params: { url: 'http://example.org/resource' }

    context 'with valid parameters' do
      before(:each) do
        delete '/api/envelopes', attributes_for(:delete_token).merge(
          url: 'http://example.org/resource'
        )
      end

      it { expect_status(:no_content) }
    end

    context 'trying to delete a non existent envelope' do
      before(:each) do
        delete '/api/envelopes', attributes_for(:delete_token).merge(
          url: 'http://example.org/non-existent-resource'
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
        delete '/api/credential-registry/envelopes',
               attributes_for(:delete_token).merge(
                 url: 'http://example.org/resource'
               )
      end

      it { expect_status(:not_found) }

      it 'does not find envelopes outside its community' do
        expect_json('errors.0', 'No matching envelopes found')
      end
    end
  end
end
