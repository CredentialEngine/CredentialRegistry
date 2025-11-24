RSpec.describe EnvelopeDumps::GraphBuilder do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:bucket) { double('bucket') } # rubocop:todo RSpec/VerifiedDoubles
  let(:bucket_name) { 'graph-downloads-bucket-test' }
  let(:envelope_download) { create(:envelope_download, envelope_community:) }
  let(:entries) { {} }
  let(:hex) { Faker::Lorem.characters.first(32) }
  let(:key) { "ce_registry_#{now.to_i}_#{hex}.zip" }
  let(:now) { Time.current.change(usec: 0) }
  let(:region) { 'aws-region-test' }
  let(:resource) { double('resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_object) { double('s3_object') } # rubocop:todo RSpec/VerifiedDoubles
  let(:url) { Faker::Internet.url }

  let(:build_dump) do
    travel_to now do
      described_class.new(envelope_download, envelope_download.started_at).run
    end
  end

  let(:envelope_community) do
    EnvelopeCommunity.find_or_create_by!(name: 'ce_registry')
  end

  let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer, updated_at: now)
  end

  let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer, updated_at: now)
  end

  let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
    create(:envelope, :from_cer, updated_at: now)
  end

  before do
    allow(ENV).to receive(:fetch).with('AWS_REGION').and_return(region)

    allow(ENV).to receive(:fetch)
      .with('ENVELOPE_GRAPHS_BUCKET')
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
        it 'creates a new download' do
          # rubocop:enable RSpec/MultipleExpectations
          build_dump
          expect(entries.size).to eq(3)

          entry1 = entries.fetch("#{envelope1.envelope_ceterms_ctid}.json")
          entry2 = entries.fetch("#{envelope2.envelope_ceterms_ctid}.json")
          entry3 = entries.fetch("#{envelope3.envelope_ceterms_ctid}.json")

          expect(entry1).to eq(envelope1.processed_resource)
          expect(entry2).to eq(envelope2.processed_resource)
          expect(entry3).to eq(envelope3.processed_resource)
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
        it 'updates the existing download' do # rubocop:todo RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          build_dump
          expect(entries.size).to eq(3)

          entry1 = entries.fetch("#{envelope1.envelope_ceterms_ctid}.json")
          entry2 = entries.fetch("#{envelope2.envelope_ceterms_ctid}.json")
          entry3 = entries.fetch("#{envelope4.envelope_ceterms_ctid}.json")

          expect(entry1).to eq({})
          expect(entry2).to eq(envelope2.processed_resource)
          expect(entry3).to eq(envelope4.processed_resource)
        end
      end
    end

    context 'with error' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:error) { StandardError.new }

      it 'notifies Airbrake and persists error' do
        allow(s3_object).to receive(:upload_file).and_raise(error)
        expect { build_dump }.to raise_error(error)
      end
    end
  end
end
