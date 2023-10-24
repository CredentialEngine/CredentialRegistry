require 'entities/envelope'
require 'envelope_download'

# Create a ZIP archive contaning all of the envelopes from a certain community,
# then uploads it to the S3 bucket
class DownloadEnvelopesJob < ActiveJob::Base
  queue_as :envelope_download

  def perform(envelope_download_id)
    envelope_download = EnvelopeDownload.find_by(id: envelope_download_id)
    return unless envelope_download

    envelope_download.update!(
      internal_error_backtrace: [],
      internal_error_message: nil,
      started_at: Time.current
    )

    envelope_download.url = upload_to_s3(envelope_download)
  rescue => e
    envelope_download.internal_error_backtrace = e.backtrace
    envelope_download.internal_error_message = e.message
  ensure
    envelope_download&.update!(finished_at: Time.current)
  end

  private

  def bucket
    ENV.fetch('ENVELOPE_DOWNLOADS_BUCKET')
  end

  def create_zip_archive(envelope_download)
    envelopes = envelope_download.envelopes.includes(
      :envelope_community, :organization, :publishing_organization
    )

    file_path = MR.root_path.join('tmp', SecureRandom.hex)

    Zip::OutputStream.open(file_path) do |stream|
      envelopes.find_each do |envelope|
        stream.put_next_entry("#{envelope.envelope_ceterms_ctid}.json")
        stream.puts(API::Entities::Envelope.represent(envelope).to_json)
      end
    end

    file_path
  end

  def region
    ENV.fetch('AWS_REGION')
  end

  def upload_to_s3(envelope_download)
    community = envelope_download.envelope_community.name
    key = "#{community}_#{Time.current.to_i}_#{SecureRandom.hex}.zip"
    path = create_zip_archive(envelope_download)
    object = Aws::S3::Resource.new(region:).bucket(bucket).object(key)
    object.upload_file(path)
    File.delete(path)
    object.public_url
  end
end
