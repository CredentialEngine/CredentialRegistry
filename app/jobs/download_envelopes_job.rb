require 'download_envelopes'
require 'envelope_download'

# Create a ZIP archive contaning all of the envelopes from a certain community,
# then uploads it to the S3 bucket
class DownloadEnvelopesJob < ActiveJob::Base
  queue_as :envelope_download

  def perform(envelope_download_id)
    envelope_download = EnvelopeDownload.find_by(id: envelope_download_id)
    return unless envelope_download

    DownloadEnvelopes.call(envelope_download:)
  rescue StandardError => e
    Airbrake.notify(e, envelope_download_id:)
    raise e
  end
end
