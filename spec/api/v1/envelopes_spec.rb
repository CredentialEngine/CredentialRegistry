require_relative 'shared_examples/signed_endpoint'

describe API::V1::Envelopes do
  let!(:envelopes) do
    [create(:envelope), create(:envelope)]
  end

  context 'GET /api/envelopes' do
    before(:each) { get '/api/envelopes' }

    it { expect_status(:ok) }

    it 'retrieves all the envelopes ordered by date' do
      expect_json_sizes(2)
      expect_json('0.envelope_id', envelopes.first.envelope_id)
    end

    it 'presents the JWT fields in decoded form' do
      expect_json('0.resource.name', 'The Constitution at Work')
    end
  end

  context 'GET /api/envelope/:id' do
    before(:each) { get "/api/envelopes/#{envelopes.first.envelope_id}" }

    it { expect_status(:ok) }

    it 'retrieves the desired envelopes' do
      expect_json(envelope_id: envelopes.first.envelope_id)
      expect_json(resource_format: 'json')
      expect_json(resource_encoding: 'jwt')
      expect_json(node_headers_format: 'node_headers_jwt')
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
    end

    context 'with invalid parameters' do
      before(:each) { post '/api/envelopes', {} }

      it { expect_status(:bad_request) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'envelope_type is missing')
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
  end

  context 'PATCH /api/envelopes/:id' do
    it_behaves_like 'a signed endpoint', :patch

    let(:envelope) { create(:envelope, :with_id) }

    context 'with valid parameters' do
      before(:each) do
        resource = jwt_encode(attributes_for(:resource, name: 'Updated'))
        patch "/api/envelopes/#{envelope.envelope_id}",
              attributes_for(:envelope, resource: resource)
      end

      it { expect_status(:no_content) }

      it 'updates some data inside the resource' do
        envelope.reload

        expect(envelope.decoded_resource.name).to eq('Updated')
      end
    end

    context 'with invalid parameters' do
      before(:each) { patch '/api/envelopes/non-existent-envelope-id', {} }

      it { expect_status(:not_found) }

      it 'returns the list of validation errors' do
        expect_json_keys(:errors)
        expect_json('errors.0', 'Couldn\'t find Envelope')
      end
    end

    context 'with a different resource and public key' do
      before(:each) do
        patch "/api/envelopes/#{envelope.envelope_id}",
              attributes_for(:envelope, :with_different_resource_and_key)
      end

      it { expect_status(:unprocessable_entity) }

      it 'raises an original user validation error' do
        expect_json('errors.0', 'can only be updated by the original user')
      end
    end
  end

  context 'DELETE /api/envelopes/:id' do
    it_behaves_like 'a signed endpoint', :delete

    context 'with valid parameters' do
      let!(:envelope) { create(:envelope) }

      before(:each) do
        delete "/api/envelopes/#{envelope.envelope_id}",
               resource_public_key: envelope.resource_public_key
      end

      it { expect_status(:no_content) }

      it 'marks the envelope as deleted' do
        envelope.reload

        expect(envelope.deleted_at).not_to be_nil
      end
    end

    context 'trying to delete a non existent envelope' do
      before(:each) { delete '/api/envelopes/non-existent-envelope-id' }

      it { expect_status(:not_found) }

      it 'returns the list of validation errors' do
        expect_json('errors.0', 'Couldn\'t find Envelope')
      end
    end
  end
end
