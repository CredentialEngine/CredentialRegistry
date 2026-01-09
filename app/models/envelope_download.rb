# Stores the status and AWS S3 URL of an asynchronously performed envelope download
class EnvelopeDownload < ActiveRecord::Base
  self.inheritance_column = nil

  belongs_to :envelope_community
  has_many :envelopes, -> { not_deleted }, through: :envelope_community

  enum :status, {
    failed: 'failed',
    finished: 'finished',
    in_progress: 'in_progress',
    pending: 'pending'
  }

  enum :type, { envelope: 'envelope', graph: 'graph' }

  def with_error?
    internal_error_message?
  end
end
