require 'extract_envelope_resources_job'

RSpec.describe ExtractEnvelopeResourcesJob do
  subject { ExtractEnvelopeResourcesJob }

  describe '#perform' do
    let(:envelope) { create(:envelope) }

    it 'calls ExtractEnvelopeResources' do
      expect(ExtractEnvelopeResources).to receive(:call)
        .with(envelope: envelope)

      subject.new.perform(envelope.id)
    end
  end
end
