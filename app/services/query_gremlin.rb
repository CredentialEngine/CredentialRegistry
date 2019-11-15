require 'rest-client'
require 'base64'
require 'zlib'
require 'json'
require 'ostruct'

# Proxies a request to Gremlin and decodes the compressed payloads.
class QueryGremlin
  HEADERS = {
    'Content-Type': 'application/json'
  }.freeze

  TIMEOUT_EXCEPTION_CLASS = 'TimedInterruptTimeoutException'.freeze

  def self.call(gremlin_query)
    new.call(gremlin_query)
  end

  def call(gremlin_query)
    logger.info(gremlin_query)
    response = make_request(gremlin_query)
    gremlin_response = JSON.parse(response.body)
    transform_payloads(gremlin_response)
    OpenStruct.new(
      result: gremlin_response,
      status: response.code
    )
  rescue RestClient::InternalServerError => e
    result = JSON.parse(e.http_body)
    exception_class = result.fetch('Exception-Class', '')
    status = exception_class.ends_with?(TIMEOUT_EXCEPTION_CLASS) ? 504 : 500

    OpenStruct.new(
      result: result,
      status: status
    )
  end

  private

  def logger
    @logger ||= Logger.new(MR.root_path.join('log', 'gremlin_queries.log'))
  end

  def make_request(gremlin_query)
    RestClient::Request.execute(
      method: :post,
      url: ENV['GREMLIN_HTTP_ENDPOINT'],
      headers: HEADERS,
      user: ENV['GREMLIN_USERNAME'],
      password: ENV['GREMLIN_PASSWORD'],
      payload: gremlin_query,
      verify_ssl: OpenSSL::SSL::VERIFY_NONE
    )
  end

  # rubocop:disable all
  def transform_payloads(parent)
    parent.each.with_index do |(k, v), i|
      # For parent = Array, the the second element will be nil.
      k, v = [i, k] if v.nil?

      if v.is_a?(String) && v.start_with?('compressed:')
        parent[k] = decompress(v)
      elsif v.is_a?(Hash) || v.is_a?(Array)
        transform_payloads(v)
      end
    end
  end
  # rubocop:enable

  def decompress(compressed)
    _, payload = compressed.split('compressed:')
    decoded = Base64.decode64(payload)
    gunzipped = gunzip(decoded)
    JSON.parse(gunzipped)
  end

  def gunzip(decoded)
    sio = StringIO.new(decoded)
    gz = Zlib::GzipReader.new(sio, encoding: Encoding::ASCII_8BIT)
    gz.read
  ensure
    gz&.close
  end
end
