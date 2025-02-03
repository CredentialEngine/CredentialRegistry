# Prevents duplicated jobs from being enqueued
module Deduplicatable
  extend ActiveSupport::Concern

  class_methods do
    def perform_later(*args)
      Sidekiq::Queue.new(queue_as).each do |job|
        metadata = job.args.first
        klass = metadata.fetch('job_class')
        params = metadata.fetch('arguments')

        # rubocop:todo Lint/NonLocalExitFromIterator
        return if klass == itself.to_s && params == args
        # rubocop:enable Lint/NonLocalExitFromIterator
      end

      super
    end
  end
end
