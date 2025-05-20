# Returns the status of the envelope's indexing job if it's enqueued
class EnvelopeIndexingStatus
  attr_reader :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  def self.call(envelope)
    new(envelope).info
  end

  def info
    { status:, enqueued_at: }
  end

  private

  def enqueued_at
    job.item.dig('args', 0, 'enqueued_at') if job
  end

  def in_progress_job
    @in_progress_job ||= Sidekiq::Workers.new.map { _1.last.job }.find(&match_job)
  end

  def job
    pending_job || in_progress_job
  end

  def match_job
    lambda do |job|
      job.item.fetch('wrapped') == 'IndexEnvelopeJob' &&
        job.item.dig('args', 0, 'arguments') == [envelope.id]
    end
  end

  def pending_job
    @pending_job ||= Sidekiq::Queue.new('default').find(&match_job)
  end

  def status
    if pending_job
      'pending'
    elsif in_progress_job
      'in_progress'
    else
      'not_enqueued'
    end
  end
end
