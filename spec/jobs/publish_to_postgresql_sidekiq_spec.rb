# frozen_string_literal: true

require 'sidekiq/api'

# Integration test: an independent Sidekiq process must consume jobs from Redis.
# The normal RSpec suite continues using ActiveJob's :test adapter.
RSpec.describe 'Publishing through a real Sidekiq worker', :sidekiq_integration do
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :sidekiq
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  def wait_until(timeout: 90)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    loop do
      result = yield
      return result if result

      raise 'Timed out waiting for Sidekiq to index the published resource' if
        Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.5
    end
  end

  it 'consumes a publish request from Redis and indexes its resource in PostgreSQL' do
    # The worker process must be genuinely connected, not an inline/fake adapter.
    wait_until(timeout: 45) { Sidekiq::ProcessSet.new.size.positive? }

    community = create(:envelope_community, name: 'ce_registry')
    organization = create(:organization)
    user = create(:user)
    create(:organization_publisher, organization: organization, publisher: user.publisher)

    resource = attributes_for(:cer_org).stringify_keys.slice(
      '@id', '@type', '@context', 'ceterms:ctid',
      'ceterms:name', 'ceterms:description', 'ceterms:subjectWebpage'
    )
    resource_id = resource.fetch('@id').downcase

    # Seed the real PostgreSQL context table so the external worker doesn't
    # depend on an HTTP request that WebMock could only stub in the RSpec process.
    JsonContext.create!(
      url: resource.fetch('@context'),
      context: {
        '@context' => {
          'ceterms:name' => { '@type' => 'xsd:string' },
          'ceterms:description' => { '@type' => 'xsd:string' },
          'ceterms:subjectWebpage' => { '@type' => 'xsd:string' }
        }
      }
    )

    publish_request = PublishRequest.schedule(
      envelope_community: community.name,
      organization_id: organization.id,
      user_id: user.id,
      raw_resource: {
        '@id' => resource_id.sub('/resources/', '/graph/'),
        '@graph' => [resource]
      }.to_json
    )

    indexed = wait_until do
      publish_request.reload
      publish_request.failed? ? :publish_failed : IndexedEnvelopeResource.find_by('@id' => resource_id)
    end

    expect(publish_request.error).to be_nil
    expect(publish_request).to be_succeeded
    expect(publish_request.envelope).to be_present
    expect(indexed).to be_a(IndexedEnvelopeResource)
    expect(indexed.envelope_resource.envelope_id).to eq(publish_request.envelope_id)
    expect(indexed.payload.fetch('ceterms:name')).to eq(resource.fetch('ceterms:name'))

    # Avoid DatabaseRewinder cleaning rows while a job is still accessing them.
    wait_until(timeout: 30) do
      Sidekiq::Queue.new('default').size.zero? &&
        Sidekiq::Workers.new.size.zero? &&
        Sidekiq::Queue.new('description_set').size.zero?
    end
  end
end
