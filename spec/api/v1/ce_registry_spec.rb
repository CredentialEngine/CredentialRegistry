describe 'CE/Registry API' do
  describe 'GET /api/:community/ctid' do
    context 'ce_registry' do
      before(:example) { get '/api/ce-registry/ctid' }

      it { expect_status(:ok) }
      it { expect(json_resp['ctid']).to match(/urn:ctid:.*/) }
    end

    context 'Other communities' do
      before(:example) { get '/api/learning-registry/ctid' }
      let(:err) { 'envelope_community does not have a valid value' }

      it { expect_status(400) }
      it { expect_json('errors', err) }
    end
  end
end
