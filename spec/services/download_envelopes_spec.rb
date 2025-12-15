RSpec.describe DownloadEnvelopes do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:builder) { double('builder') } # rubocop:todo RSpec/VerifiedDoubles
  let(:envelope_download) { create(:envelope_download, type:) }
  let(:error) { StandardError.new(error_message) }
  let(:error_message) { Faker::Lorem.sentence }
  let(:now) { Date.current }
  let(:url) { Faker::Internet.url }

  let(:download_envelopes) do
    travel_to now do
      described_class.call(envelope_download:)
    end
  end

  before do
    allow(builder_class).to receive(:new)
      .with(envelope_download, envelope_download.started_at)
      .and_return(builder)
  end

  describe '.call' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'with envelope builder' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:builder_class) { EnvelopeDumps::EnvelopeBuilder }
      let(:type) { :envelope }

      # rubocop:todo RSpec/NestedGroups
      context 'with error' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          allow(builder).to receive(:run).and_raise(error)
        end

        it 'stores error message' do
          expect do
            download_envelopes
            envelope_download.reload
          end.to change(envelope_download, :status).to('failed')
                                                   .and change(envelope_download,
                                                               # rubocop:todo Layout/LineLength
                                                               :internal_error_message).to(error_message)
            # rubocop:enable Layout/LineLength
            .and change(envelope_download,
                        :started_at).to(now)
            .and change(envelope_download,
                        :finished_at).to(now)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without error' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          allow(builder).to receive(:run).and_return(url)
        end

        it 'stores URL' do # rubocop:todo RSpec/ExampleLength
          expect do
            download_envelopes
            envelope_download.reload
          end.to change(envelope_download, :status).to('finished')
                                                   .and change(envelope_download, :url).to(url)
                                                                                       .and change(
                                                                                         # rubocop:todo Layout/LineLength
                                                                                         envelope_download, :started_at
                                                                                         # rubocop:enable Layout/LineLength
                                                                                       ).to(now)
            .and change(
              envelope_download, :finished_at
            ).to(now)
        end
      end
    end

    context 'with graph builder' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:builder_class) { EnvelopeDumps::GraphBuilder }
      let(:type) { :graph }

      # rubocop:todo RSpec/NestedGroups
      context 'with error' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          allow(builder).to receive(:run).and_raise(error)
        end

        it 'stores error message' do
          expect do
            download_envelopes
            envelope_download.reload
          end.to change(envelope_download, :status).to('failed')
                                                   .and change(envelope_download,
                                                               # rubocop:todo Layout/LineLength
                                                               :internal_error_message).to(error_message)
            # rubocop:enable Layout/LineLength
            .and change(envelope_download,
                        :started_at).to(now)
            .and change(envelope_download,
                        :finished_at).to(now)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without error' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          allow(builder).to receive(:run).and_return(url)
        end

        it 'stores URL' do # rubocop:todo RSpec/ExampleLength
          expect do
            download_envelopes
            envelope_download.reload
          end.to change(envelope_download, :status).to('finished')
                                                   .and change(envelope_download, :url).to(url)
                                                                                       .and change(
                                                                                         # rubocop:todo Layout/LineLength
                                                                                         envelope_download, :started_at
                                                                                         # rubocop:enable Layout/LineLength
                                                                                       ).to(now)
            .and change(
              envelope_download, :finished_at
            ).to(now)
        end
      end
    end
  end
end
