require 'json'
require 'rack/request'

# Rack middleware that emits a single JSON log line per request
class JsonRequestLogger
  REDACT_KEYS = %w[password passwd secret token api_key authorization auth jwt bearer].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = nil
    headers = nil
    body = nil
    begin
      status, headers, body = @app.call(env)
      status
    ensure
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000.0).round(2)
      req = Rack::Request.new(env)
      path = req.fullpath rescue env['PATH_INFO']
      params = safe_params(req)
      labels = {
        method: req.request_method,
        path: path,
        status: status || 500,
        duration_ms: duration_ms,
        ip: req.ip,
        ua: req.user_agent,
        request_id: env['HTTP_X_REQUEST_ID'] || env['action_dispatch.request_id'] || env['REQUEST_ID']
      }
      # Prefer structured logging through MR helper if available
      if defined?(MR) && MR.respond_to?(:log_with_labels)
        MR.log_with_labels(:info, 'request', labels)
      else
        line = { message: 'request' }.merge(labels)
        (defined?(MR) && MR.logger || Logger.new($stdout)).info(line.to_json)
      end
    end
    [status, headers, body]
  end

  private

  def safe_params(req)
    params = req.params rescue {}
    redact(params)
  end

  def redact(obj)
    case obj
    when Hash
      obj.transform_keys(&:to_s).each_with_object({}) do |(k, v), h|
        if REDACT_KEYS.any? { |rk| k.downcase.include?(rk) }
          h[k] = '[FILTERED]'
        else
          h[k] = redact(v)
        end
      end
    when Array
      obj.map { |v| redact(v) }
    else
      obj
    end
  end
end

