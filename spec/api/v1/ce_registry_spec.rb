RSpec.describe 'CE/Registry API' do # rubocop:todo RSpec/DescribeClass
  describe 'GET /:community/ctid' do
    context 'ce_registry' do # rubocop:todo RSpec/ContextWording
      before { get '/ce-registry/ctid' }

      it { expect_status(:ok) }
      it { expect(json_resp['ctid']).to match(/urn:ctid:.*/) }
    end

    context 'Other communities' do # rubocop:todo RSpec/ContextWording
      before { get '/learning-registry/ctid' }

      let(:err) { 'envelope_community does not have a valid value' }

      it { expect_status(400) }
      it { expect_json('errors', err) }
    end
  end
end
