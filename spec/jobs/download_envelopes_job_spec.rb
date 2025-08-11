require 'spec_helper'

RSpec.describe DownloadEnvelopesJob do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:bucket) { double('bucket') } # rubocop:todo RSpec/VerifiedDoubles
  let(:bucket_name) { 'envelope-downloads-bucket-test' }
  let(:envelope_download) { create(:envelope_download, envelope_community:) }
  let(:hex) { Faker::Lorem.characters }
  let(:key) { "ce_registry_#{now.to_i}_#{hex}.zip" }
  let(:now) { Time.current.change(usec: 0) }
  let(:object) { double('object') } # rubocop:todo RSpec/VerifiedDoubles
  let(:region) { 'aws-region-test' }
  let(:resource) { double('resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:url) { Faker::Internet.url }

  let(:envelope_community) do
    EnvelopeCommunity.find_or_create_by!(name: 'ce_registry')
  end

  let(:perform) do
    travel_to now do
      described_class.new.perform(envelope_download.id)
    end
  end

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'no download' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    it 'does nothing' do
      expect(described_class.new.perform(Faker::Lorem.word)).to be_nil
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'with download' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
      create(:envelope, :from_cer)
    end

    let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
      create(:envelope, :from_cer, :with_cer_credential)
    end

    before do
      allow(ENV).to receive(:fetch).with('AWS_REGION').and_return(region)

      allow(ENV).to receive(:fetch)
        .with('ENVELOPE_DOWNLOADS_BUCKET')
        .and_return(bucket_name)

      allow(Aws::S3::Resource).to receive(:new)
        .with(region:)
        .and_return(resource)

      allow(SecureRandom).to receive(:hex).and_return(hex)

      allow(resource).to receive(:bucket).with(bucket_name).and_return(bucket)
      allow(bucket).to receive(:object).with(key).and_return(object)
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'no error' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        # rubocop:todo RSpec/MessageSpies
        expect(object).to receive(:upload_file) do |path| # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          entries = {}

          Zip::InputStream.open(path) do |stream|
            loop do
              entry = stream.get_next_entry
              break unless entry

              entries[entry.name] = JSON(stream.read)
            end
          end

          entry1 = entries.fetch("#{envelope1.envelope_ceterms_ctid}.json")
          entry2 = entries.fetch("#{envelope2.envelope_ceterms_ctid}.json")

          expect(entry1.fetch('envelope_ceterms_ctid')).to eq( # rubocop:todo RSpec/ExpectInHook
            envelope1.envelope_ceterms_ctid
          )
          expect(entry1.fetch('decoded_resource')).to eq( # rubocop:todo RSpec/ExpectInHook
            envelope1.processed_resource
          )
          # rubocop:todo RSpec/ExpectInHook
          expect(entry1.fetch('updated_at').to_time).to be_within(1.second).of(
            # rubocop:enable RSpec/ExpectInHook
            envelope1.updated_at
          )

          expect(entry2.fetch('envelope_ceterms_ctid')).to eq( # rubocop:todo RSpec/ExpectInHook
            envelope2.envelope_ceterms_ctid
          )
          expect(entry2.fetch('decoded_resource')).to eq( # rubocop:todo RSpec/ExpectInHook
            envelope2.processed_resource
          )
          # rubocop:todo RSpec/ExpectInHook
          expect(entry2.fetch('updated_at').to_time).to be_within(1.second).of(
            # rubocop:enable RSpec/ExpectInHook
            envelope2.updated_at
          )
        end

        # rubocop:todo RSpec/StubbedMock
        # rubocop:todo RSpec/MessageSpies
        expect(object).to receive(:public_url).and_return(url) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
        # rubocop:enable RSpec/MessageSpies
        # rubocop:enable RSpec/StubbedMock
      end

      it 'creates and uploads ZIP archive to S3' do
        expect do
          perform
          envelope_download.reload
        end.to change(envelope_download, :finished_at).to(now)
                                                      .and change(envelope_download, :url).to(url)
                                                                                          # rubocop:todo Layout/LineLength
                                                                                          .and not_change {
                                                                                                 # rubocop:enable Layout/LineLength
                                                                                                 # rubocop:todo Layout/LineLength
                                                                                                 envelope_download.internal_error_message
                                                                                                 # rubocop:enable Layout/LineLength
                                                                                               }
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'with error' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:error) { StandardError.new(error_message) }
      let(:error_message) { Faker::Lorem.sentence }

      before do
        # rubocop:todo RSpec/MessageSpies
        expect(Airbrake).to receive(:notify).with(error, # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
                                                  # rubocop:enable RSpec/MessageSpies
                                                  envelope_download_id: envelope_download.id)
      end

      # rubocop:todo RSpec/NestedGroups
      context 'when EnvelopeDownload.find_by fails' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          # rubocop:todo Layout/LineLength
          expect(EnvelopeDownload).to receive(:find_by).with(id: envelope_download.id).and_raise(error) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
          # rubocop:enable Layout/LineLength
          # rubocop:enable RSpec/MessageSpies
          # rubocop:enable RSpec/StubbedMock
        end

        it 'notifies Airbrake' do # rubocop:todo RSpec/ExampleLength
          expect do
            perform
            envelope_download.reload
          end.to not_change(envelope_download,
                            :finished_at).and not_change(envelope_download,
                                                         :internal_error_backtrace)
            .and not_change(envelope_download,
                            :internal_error_message)
            .and not_change {
                   envelope_download.url
                 }
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'when Aws::S3::Object#upload_file fails' do # rubocop:todo RSpec/NestedGroups
        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(object).to receive(:upload_file).and_raise(error) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
          # rubocop:enable RSpec/MessageSpies
          # rubocop:enable RSpec/StubbedMock
        end

        it 'notifies Airbrake and persists error' do
          expect do
            perform
            envelope_download.reload
          end.to change(envelope_download, :finished_at).to(now)
                                                        .and change(envelope_download,
                                                                    # rubocop:todo Layout/LineLength
                                                                    :internal_error_message).to(error_message)
                                                                                            # rubocop:enable Layout/LineLength
                                                                                            # rubocop:todo Layout/LineLength
                                                                                            .and not_change {
                                                                                                   # rubocop:enable Layout/LineLength
                                                                                                   # rubocop:todo Layout/LineLength
                                                                                                   envelope_download.url
                                                                                                   # rubocop:enable Layout/LineLength
                                                                                                 }
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end
end
