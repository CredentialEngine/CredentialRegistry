require 'spec_helper'

RSpec.describe DownloadEnvelopesJob do
  let(:envelope_download) { create(:envelope_download) }

  describe '#perform' do
    context 'without error' do
      it 'calls DownloadEnvelopes' do
        allow(DownloadEnvelopes).to receive(:call).with(envelope_download:)
        described_class.new.perform(envelope_download.id)
      end
    end

    context 'with error' do
      let(:error) { StandardError.new }

      it 'logs error' do
        allow(Airbrake).to receive(:notify)
          .with(error, envelope_download_id: envelope_download.id)

        allow(DownloadEnvelopes).to receive(:call)
          .with(envelope_download:)
          .and_raise(error)

        expect { described_class.new.perform(envelope_download.id) }.to raise_error(error)
      end
    end
  end
end
