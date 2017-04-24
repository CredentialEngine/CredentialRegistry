require_relative 'shared_examples/missing_envelope'

describe API::V1::SingleEnvelope do
  context 'GET /:community/envelopes/:id' do
    let!(:envelopes) do
      [create(:envelope), create(:envelope)]
    end

    include_examples 'missing envelope', :get

    subject { envelopes.first }

    before(:each) do
      with_versioned_envelope(subject) do
        get "/learning-registry/envelopes/#{subject.envelope_id}"
      end
    end

    it { expect_status(:ok) }

    it 'retrieves the desired envelope' do
      expect_json(envelope_community: subject.envelope_community.name)
      expect_json(envelope_id: subject.envelope_id)
      expect_json(resource_format: 'json')
      expect_json(resource_encoding: 'jwt')
    end

    it 'displays the appended node headers' do
      base_url = "/learning-registry/envelopes/#{subject.envelope_id}"

      expect_json_keys('node_headers', %i[resource_digest versions created_at
                                          updated_at deleted_at])
      expect_json('node_headers.versions.1', head: true)
      expect_json('node_headers.versions.1', url: base_url)
      expect_json('node_headers.versions.0', head: false)
      expect_json('node_headers.versions.0',
                  url: "#{base_url}/versions/#{subject.versions.last.id}")
    end
  end

  context 'PATCH /:community/envelopes/:id' do
    it_behaves_like 'a signed endpoint', :patch, uses_id: true
    include_examples 'missing envelope', :patch do
      let(:params) { attributes_for(:envelope) }
    end

    let!(:envelope) { create(:envelope) }

    context 'with valid parameters' do
      before(:each) do
        resource = jwt_encode(attributes_for(:resource, name: 'Updated'))
        patch "/learning-registry/envelopes/#{envelope.envelope_id}",
              attributes_for(:envelope, resource: resource)
      end

      it { expect_status(:ok) }

      it 'updates some data inside the resource' do
        envelope.reload

        expect(envelope.decoded_resource.name).to eq('Updated')
      end

      it 'returns the updated envelope' do
        expect_json(envelope_id: envelope.envelope_id)
        expect_json(envelope_community: envelope.envelope_community.name)
        expect_json(envelope_version: envelope.envelope_version)
      end
    end

    context 'with a different resource and public key' do
      before(:each) do
        patch "/learning-registry/envelopes/#{envelope.envelope_id}",
              attributes_for(:envelope, :from_different_user)
      end

      it { expect_status(:unprocessable_entity) }

      it 'raises an original user validation error' do
        expect_json('errors.0', 'can only be updated by the original user')
      end
    end
  end

  context 'DELETE /:community/envelopes/:id' do
    let!(:envelope) { create(:envelope) }

    it_behaves_like 'a signed endpoint', :delete, uses_id: true
    include_examples 'missing envelope', :delete do
      let(:params) { attributes_for(:delete_token) }
    end

    context 'with valid parameters' do
      before(:each) do
        delete "/learning-registry/envelopes/#{envelope.envelope_id}",
               attributes_for(:delete_token)
      end

      it { expect_status(:no_content) }

      it 'marks the envelope as deleted' do
        envelope.reload

        expect(envelope.deleted_at).not_to be_nil
      end
    end

    context 'with invalid parameters' do
      before(:each) do
        delete "/learning-registry/envelopes/#{envelope.envelope_id}",
               attributes_for(:delete_envelope).merge(delete_token_format: 'no')
      end

      it { expect_status(:unprocessable_entity) }
      it { expect_json('errors.0', /delete_token_format : Must be one of .*/) }
    end
  end
end
