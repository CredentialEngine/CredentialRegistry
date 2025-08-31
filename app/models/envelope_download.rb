# Stores the status and AWS S3 URL of an asynchronously performed envelope download
class EnvelopeDownload < ActiveRecord::Base
  belongs_to :envelope_community
  has_many :envelopes, -> { not_deleted }, through: :envelope_community

  enum :status, {
    finished: 'finished',
    in_progress: 'in_progress',
    pending: 'pending'
  }

  def display_status
    return 'failed' if internal_error_message?

    status
  end
end
