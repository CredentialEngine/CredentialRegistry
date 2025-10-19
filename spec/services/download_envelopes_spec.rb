RSpec.describe DownloadEnvelopes do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:bucket) { double('bucket') } # rubocop:todo RSpec/VerifiedDoubles
  let(:bucket_name) { 'envelope-downloads-bucket-test' }
  let(:envelope_download) { create(:envelope_download, envelope_community:) }
  let(:entries) { {} }
  let(:hex) { Faker::Lorem.characters.first(32) }
  let(:key) { "ce_registry_#{now.to_i}_#{hex}.zip" }
  let(:now) { Time.current.change(usec: 0) }
  let(:region) { 'aws-region-test' }
  let(:resource) { double('resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_object) { double('s3_object') } # rubocop:todo RSpec/VerifiedDoubles
  let(:url) { Faker::Internet.url }

  let(:download_envelopes) do
    travel_to now do
      described_class.call(envelope_download:)
    end
  end

  let(:envelope_community) do
    EnvelopeCommunity.find_or_create_by!(name: 'ce_registry')
  end

  let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer)
  end

  let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer)
  end

  let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer)
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
    allow(bucket).to receive(:object).with(key).and_return(s3_object)
  end

  describe '.call' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'without error' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      before do
        allow(s3_object).to receive(:upload_file) do |path|
          Zip::InputStream.open(path) do |stream|
            loop do
              entry = stream.get_next_entry
              break unless entry

              entries[entry.name] = JSON(stream.read)
            end
          end
        end

        allow(s3_object).to receive(:public_url).and_return(url)
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without previous download' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleExpectations
        it 'creates a new download' do # rubocop:todo RSpec/ExampleLength
          # rubocop:enable RSpec/MultipleExpectations
          download_envelopes
          expect(entries.size).to eq(3)

          entry1 = entries.fetch("#{envelope1.envelope_ceterms_ctid}.json")
          entry2 = entries.fetch("#{envelope2.envelope_ceterms_ctid}.json")
          entry3 = entries.fetch("#{envelope3.envelope_ceterms_ctid}.json")

          expect(entry1.fetch('envelope_ceterms_ctid')).to eq(
            envelope1.envelope_ceterms_ctid
          )
          expect(entry1.fetch('decoded_resource')).to eq(
            envelope1.processed_resource
          )
          expect(entry1.fetch('updated_at').to_time).to be_within(1.second).of(
            envelope1.updated_at
          )

          expect(entry2.fetch('envelope_ceterms_ctid')).to eq(
            envelope2.envelope_ceterms_ctid
          )
          expect(entry2.fetch('decoded_resource')).to eq(
            envelope2.processed_resource
          )
          expect(entry2.fetch('updated_at').to_time).to be_within(1.second).of(
            envelope2.updated_at
          )

          expect(entry3.fetch('envelope_ceterms_ctid')).to eq(
            envelope3.envelope_ceterms_ctid
          )
          expect(entry3.fetch('decoded_resource')).to eq(
            envelope3.processed_resource
          )
          expect(entry3.fetch('updated_at').to_time).to be_within(1.second).of(
            envelope3.updated_at
          )

          expect(envelope_download.internal_error_message).to be_nil
          expect(envelope_download.status).to eq('finished')
          expect(envelope_download.url).to eq(url)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with previous download' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:dump) do
          buffer = StringIO.new

          Zip::OutputStream.write_buffer(buffer) do |stream|
            [envelope1, envelope2, envelope3].each do |envelope|
              stream.put_next_entry("#{envelope.envelope_ceterms_ctid}.json")
              stream.puts('{}')
            end
          end

          buffer.string
        end

        let(:envelope_download) do
          create(
            :envelope_download,
            envelope_community:,
            started_at: now + 1.second,
            url: Faker::Internet.url
          )
        end

        let!(:envelope4) do
          create(:envelope, :from_cer, updated_at: envelope_download.started_at)
        end

        before do
          PaperTrail.enabled = true

          envelope2.update_column(:updated_at, envelope_download.started_at)

          travel_to envelope_download.started_at do
            envelope3.destroy
          end

          stub_request(:get, envelope_download.url).to_return(body: dump)
        end

        after do
          PaperTrail.enabled = false
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'updates the existing download' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          download_envelopes
          expect(entries.size).to eq(3)

          entry1 = entries.fetch("#{envelope1.envelope_ceterms_ctid}.json")
          entry2 = entries.fetch("#{envelope2.envelope_ceterms_ctid}.json")
          entry3 = entries.fetch("#{envelope4.envelope_ceterms_ctid}.json")

          expect(entry1).to eq({})

          expect(entry2.fetch('envelope_ceterms_ctid')).to eq(
            envelope2.envelope_ceterms_ctid
          )
          expect(entry2.fetch('decoded_resource')).to eq(
            envelope2.processed_resource
          )
          expect(entry2.fetch('updated_at').to_time).to be_within(1.second).of(
            envelope2.updated_at
          )

          expect(entry3.fetch('envelope_ceterms_ctid')).to eq(
            envelope4.envelope_ceterms_ctid
          )
          expect(entry3.fetch('decoded_resource')).to eq(
            envelope4.processed_resource
          )
          expect(entry3.fetch('updated_at').to_time).to be_within(1.second).of(
            envelope4.updated_at
          )

          expect(envelope_download.internal_error_message).to be_nil
          expect(envelope_download.status).to eq('finished')
          expect(envelope_download.url).to eq(url)
        end
      end
    end

    context 'with error' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:error) { StandardError.new(error_message) }
      let(:error_message) { Faker::Lorem.sentence }

      it 'notifies Airbrake and persists error' do # rubocop:todo RSpec/ExampleLength
        allow(Airbrake).to receive(:notify).with(error)
        allow(s3_object).to receive(:upload_file).and_raise(error)

        expect do
          download_envelopes
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
  end
end
