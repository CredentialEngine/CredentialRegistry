# Proxies SPARQL requests to Neptune
class QuerySparql
  ALLOWED_KEYS = %w[explain query update].freeze

  def self.call(payload)
    params = payload.slice(*ALLOWED_KEYS)

    response = RestClient::Request.execute(
      method: :post,
      payload: URI.encode_www_form(params),
      timeout: nil,
      url: ENV.fetch('NEPTUNE_SPARQL_ENDPOINT')
    )

    content_type = response.net_http_res.header['Content-Type']
    result = response.body

    if params.key?('explain')
      content_type = 'text/plain'
      result = result.force_encoding('UTF-8')
    end

    if content_type == 'application/n-quads'
      content_type = 'application/json'
      input = RDF::Graph.new << RDF::NTriples::Reader.new(result)
      result = JSON::LD::API::fromRdf(input).to_json
    end

    OpenStruct.new(
      content_type: content_type,
      result: result,
      status: response.code
    )
  rescue RestClient::Exception => e
    OpenStruct.new(
      content_type: 'application/json',
      result: e.http_body ? e.http_body : { error: e.message }.to_json,
      status: e.http_code || 500
    )
  end
end
