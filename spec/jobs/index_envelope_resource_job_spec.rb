require 'index_envelope_resource_job'

RSpec.describe IndexEnvelopeResourceJob do
  describe '#perform' do
    let(:resource) { create(:envelope_resource) }

    context 'nonexistent resource ID' do
      it 'calls IndexEnvelopeResource' do
        expect(IndexEnvelopeResource).to receive(:call).with(resource)
        IndexEnvelopeResourceJob.new.perform(resource.id)
      end
    end

    context 'nonexistent resource ID' do
      it 'does nothing' do
        expect(IndexEnvelopeResource).not_to receive(:call)
        IndexEnvelopeResourceJob.new.perform(0)
      end
    end
  end
end
