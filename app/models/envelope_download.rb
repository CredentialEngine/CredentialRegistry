require 'download_envelopes_job'

# Stores the status and AWS S3 URL of an asynchronously performed envelope download
class EnvelopeDownload < ActiveRecord::Base
  belongs_to :envelope_community
  has_many :envelopes, -> { not_deleted }, through: :envelope_community

  after_commit :enqueue_job, on: :create

  def status
    if finished_at?
      return internal_error_message? ? 'failed' : 'finished'
    elsif started_at?
      return 'in progress'
    end

    'pending'
  end

  private

  def enqueue_job
    DownloadEnvelopesJob.perform_later(id)
  end
end
