require 'extract_envelope_resources_job'
require 'index_envelope_job'

RSpec.describe ExtractEnvelopeResourcesJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }

    before do
      expect(ExtractEnvelopeResources).to receive(:call).with(envelope:)
      expect(IndexEnvelopeJob).to receive(:perform_later).with(envelope.id)
    end

    it 'calls ExtractEnvelopeResources' do
      ExtractEnvelopeResourcesJob.new.perform(envelope.id)
    end
  end
end
