Sidekiq.configure_server do |config|
  config.capsule('envelope-download') do |capsule|
    capsule.concurrency = 1
    capsule.queues = %w[envelope_download]
  end

  config.redis = { db: ENV['REDIS_DB'].to_i } if MR.development?
end

Sidekiq.configure_client do |config|
  if MR.development?
    config.logger = nil
    config.redis = { db: ENV['REDIS_DB'].to_i }
  end
end
