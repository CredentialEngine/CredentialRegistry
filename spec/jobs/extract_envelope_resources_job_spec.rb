require 'extract_envelope_resources_job'
require 'index_envelope_job'

RSpec.describe ExtractEnvelopeResourcesJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }

    before do
      # rubocop:todo RSpec/MessageSpies
      # rubocop:todo RSpec/ExpectInHook
      expect(ExtractEnvelopeResources).to receive(:call).with(envelope:)
      # rubocop:enable RSpec/ExpectInHook
      # rubocop:enable RSpec/MessageSpies
      # rubocop:todo RSpec/MessageSpies
      # rubocop:todo RSpec/ExpectInHook
      expect(IndexEnvelopeJob).to receive(:perform_later).with(envelope.id)
      # rubocop:enable RSpec/ExpectInHook
      # rubocop:enable RSpec/MessageSpies
    end

    it 'calls ExtractEnvelopeResources' do
      described_class.new.perform(envelope.id)
    end
  end
end
