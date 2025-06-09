require 'logger'
require 'http'
require 'json'
require 'openssl'

class LokiLogger < Logger
  def initialize(loki_url:, default_labels: {}, username: nil, password: nil)
    super(nil)
    @loki_url = loki_url
    @default_labels = default_labels
    @username = username
    @password = password
    @insecure_ssl_ctx = OpenSSL::SSL::SSLContext.new
    @insecure_ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def add(severity, message = nil, progname = nil, labels: {})
    log_time = (Time.now.to_f * 1_000_000_000).to_i.to_s
    full_labels = @default_labels.merge(labels)
    payload = {
      streams: [
        {
          stream: full_labels,
          values: [[log_time, (message || progname || '')]]
        }
      ]
    }

    headers = {
      "Content-Type" => "application/json"
    }
    headers["X-Scope-OrgID"] = ENV['LOKI_ORG_ID'] if ENV['LOKI_ORG_ID']

    http = HTTP.headers(headers)
    http = http.basic_auth(user: @username, pass: @password) if @username && @password

    http.post(@loki_url, body: payload.to_json, ssl_context: @insecure_ssl_ctx)
  rescue => e
    STDERR.puts "[LokiLogger Error]: #{e.class} #{e.message}"
  end
end