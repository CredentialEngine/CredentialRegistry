# Returns the status of the envelope's indexing job if it's enqueued
class IndexerStats
  attr_reader :community_name

  def initialize(community_name)
    @community_name = community_name
  end

  def self.call(community_name)
    new(community_name).counts
  end

  def counts
    {
      enqueued_jobs: count_envelopes(enqueued_jobs),
      in_progress_jobs: count_envelopes(in_progress_jobs)
    }
  end

  private

  def count_envelopes(jobs)
    ids = jobs.map { it.item.dig('args', 0, 'arguments', 0) }
    Envelope.in_community(community_name).where(id: ids).count
  end

  def in_progress_jobs
    @in_progress_jobs ||= Sidekiq::Workers.new.map { it.last.job }
  end

  def enqueued_jobs
    @enqueued_jobs ||= Sidekiq::Queue
                       .new('default')
                       .select { it.item.fetch('wrapped') == 'IndexEnvelopeJob' }
  end
end
