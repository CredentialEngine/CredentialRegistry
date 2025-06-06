# lib/loki_logger.rb
require 'logger'
require 'http'
require 'json'

class LokiLogger < Logger
  def initialize(loki_url:, default_labels: {})
    super(nil)
    @loki_url = loki_url
    @default_labels = default_labels
  end

  # Accepts log message and optional labels hash
  def add(severity, message = nil, progname = nil, labels: {})
    log_time = (Time.now.to_f * 1_000_000_000).to_i.to_s # nanoseconds
    full_labels = @default_labels.merge(labels)
    payload = {
      streams: [
        {
          stream: full_labels,
          values: [[log_time, (message || progname || '')]]
        }
      ]
    }

    # Send log as HTTP POST to Loki
    HTTP.headers("Content-Type" => "application/json")
        .post(@loki_url, body: payload.to_json)
  rescue => e
    # Fallback or log error to STDERR or file
    STDERR.puts "[LokiLogger Error]: #{e.class} #{e.message}"
  end
end