RSpec.describe 'API info' do # rubocop:todo RSpec/DescribeClass
  before do
    @envelope = create(:envelope)
    create(:envelope, :from_cer)
  end

  context 'GET /:community/community/info' do # rubocop:todo RSpec/ContextWording
    before { get '/learning-registry/community/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the node' do
      expect_json(total_envelopes: 1)
      expect_json(backup_item: 'learning-registry-test')
    end
  end

  context 'GET /:community/envelopes/info' do # rubocop:todo RSpec/ContextWording
    before { get '/learning-registry/envelopes/info' }

    it { expect_status(:ok) }

    it 'retrieves info about the envelopes' do
      expect_json_keys %i[POST PUT]
    end
  end

  context 'GET /:community/envelopes/:id/info' do # rubocop:todo RSpec/ContextWording
    before do
      # rubocop:todo RSpec/InstanceVariable
      get "/learning-registry/envelopes/#{@envelope.envelope_id}/info"
      # rubocop:enable RSpec/InstanceVariable
    end

    context 'by ID' do # rubocop:todo RSpec/ContextWording
      let(:id) { envelope.envelope_id }

      it { expect_status(:ok) }

      it 'retrieves info about the envelope' do
        expect_json_keys %i[PATCH DELETE]
      end
    end

    context 'by CTID' do # rubocop:todo RSpec/ContextWording
      let(:id) { envelope.envelope_ceterms_ctid }

      it { expect_status(:ok) }

      it 'retrieves info about the envelope' do
        expect_json_keys %i[PATCH DELETE]
      end
    end
  end
end
