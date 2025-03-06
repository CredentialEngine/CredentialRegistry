RSpec::Matchers.define :enqueue_job do |job_class|
  def normalize_args(args)
    args.map do |arg|
      next arg unless arg.is_a?(Hash)

      arg.except('_aj_ruby2_keywords').transform_keys(&:to_sym)
    end
  end

  match do |proc|
    previous_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.dup
    proc.call
    current_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.dup

    @namesake_jobs = (current_jobs - previous_jobs)
                     .select { _1[:job] == job_class }
                     .map { OpenStruct.new(args: normalize_args(_1[:args]), name: _1[:job]) }

    @matched_jobs = @namesake_jobs.select { _1.args == @expected_args }
    @matched_jobs.any?
  end

  chain :with do |*expected_args|
    @expected_args = normalize_args(expected_args)
  end

  failure_message do
    if @namesake_jobs.any?
      "expected #{job_class} to be enqueued with #{@expected_args}, " \
        "but it was enqueued with #{@namesake_jobs.first.args}"
    else
      "expected #{job_class} to be enqueued, but it wasn't"
    end
  end

  failure_message_when_negated do
    "expected #{job_class} not to be enqueued with #{@expected_args}, but it was"
  end

  description do
    description = "enqueue #{job_class}"
    description += " with #{@expected_args}" if @expected_args
    description
  end

  supports_block_expectations
end
