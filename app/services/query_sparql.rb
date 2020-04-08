# Proxies SPARQL requests to Neptune
class QuerySparql
  ALLOWED_KEYS = %w[explain query update].freeze

  def self.call(payload, explain_mode: nil)
    params = payload.slice(*ALLOWED_KEYS)

    response = RestClient::Request.execute(
      method: :post,
      payload: URI.encode_www_form(params),
      timeout: nil,
      url: ENV.fetch('NEPTUNE_SPARQL_ENDPOINT')
    )

    result =
      if params.key?('explain')
        response.body.force_encoding('UTF-8')
      else
        JSON(response.body)
      end

    OpenStruct.new(result: result, status: response.code)
  rescue RestClient::Exception => e
    OpenStruct.new(
      result: e.http_body ? JSON(e.http_body) : { error: e.message },
      status: e.http_code || 500
    )
  end
end
