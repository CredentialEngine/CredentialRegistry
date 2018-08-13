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

  def self.call(gremlin_query)
    new.call(gremlin_query)
  end

  def call(gremlin_query)
    response = make_request(gremlin_query)
    gremlin_response = JSON.parse(response.body)
    transform_payloads(gremlin_response)
    OpenStruct.new(
      result: gremlin_response,
      status: response.code
    )
  rescue RestClient::InternalServerError => e
    OpenStruct.new(
      result: JSON.parse(e.http_body),
      status: 500
    )
  end

  private

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
    if parent.is_a?(Hash)
      parent.each do |k, v|
        if v.is_a?(String) && v.start_with?('compressed:')
          parent[k] = decompress(v)
        elsif v.is_a?(Hash) || v.is_a?(Array)
          transform_payloads(v)
        end
      end
    elsif parent.is_a?(Array)
      parent.each_with_index do |v, idx|
        if v.is_a?(String) && v.start_with?('compressed:')
          parent[idx] = decompress(v)
        else
          transform_payloads(v)
        end
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
