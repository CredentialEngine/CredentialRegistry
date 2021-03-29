require 'index_envelope_resource_job'

RSpec.describe IndexEnvelopeResourceJob do
  describe '#perform' do
    let(:resource) { create(:envelope_resource) }

    it 'calls IndexEnvelopeResource' do
      expect(IndexEnvelopeResource).to receive(:call).with(resource)
      IndexEnvelopeResourceJob.new.perform(resource.id)
    end
  end
end
