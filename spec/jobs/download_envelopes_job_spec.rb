require 'spec_helper'

RSpec.describe DownloadEnvelopesJob do
  let(:bucket) { double('bucket') }
  let(:bucket_name) { 'envelope-downloads-bucket-test' }
  let(:envelope_download) { create(:envelope_download, envelope_community:) }
  let(:hex) { Faker::Lorem.characters }
  let(:key) { "ce_registry_#{now.to_i}_#{hex}.zip" }
  let(:now) { Time.current.change(usec: 0) }
  let(:object) { double('object') }
  let(:region) { 'aws-region-test' }
  let(:resource) { double('resource') }
  let(:url) { Faker::Internet.url }

  let(:envelope_community) do
    EnvelopeCommunity.find_or_create_by!(name: 'ce_registry')
  end

  let(:perform) do
    travel_to now do
      DownloadEnvelopesJob.new.perform(envelope_download.id)
    end
  end

  context 'no download' do
    it 'does nothing' do
      expect(DownloadEnvelopesJob.new.perform(Faker::Lorem.word)).to eq(nil)
    end
  end

  context 'with download' do
    let!(:envelope1) do
      create(:envelope, :from_cer)
    end

    let!(:envelope2) do
      create(:envelope, :from_cer, :with_cer_credential)
    end

    before do
      allow(ENV).to receive(:fetch).with('AWS_REGION').and_return(region)

      allow(ENV).to receive(:fetch)
        .with('ENVELOPE_DOWNLOADS_BUCKET')
        .and_return(bucket_name)

      expect(SecureRandom).to receive(:hex).and_return(hex)

      expect(Aws::S3::Resource).to receive(:new)
        .with(region:)
        .and_return(resource)

      expect(resource).to receive(:bucket).with(bucket_name).and_return(bucket)
      expect(bucket).to receive(:object).with(key).and_return(object)
    end

    context 'no error' do
      before do
        expect(object).to receive(:upload_file) do |path|
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
        end

        expect(object).to receive(:public_url).and_return(url)
      end

      it 'creates and uploads ZIP archive to S3' do
        expect {
          perform
          envelope_download.reload
        }.to change { envelope_download.finished_at }.to(now)
        .and change { envelope_download.url }.to(url)
        .and not_change { envelope_download.internal_error_message }
      end
    end

    context 'with error' do
      let(:error) { Faker::Lorem.sentence }

      before do
        expect(object).to receive(:upload_file).and_raise(error)
      end

      it 'persists error' do
        expect {
          perform
          envelope_download.reload
        }.to change { envelope_download.finished_at }.to(now)
        .and change { envelope_download.internal_error_message }.to(error)
        .and not_change { envelope_download.url }
      end
    end
  end
end
