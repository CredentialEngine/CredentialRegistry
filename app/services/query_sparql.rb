# Proxies SPARQL requests to Neptune
class QuerySparql
  QUERY_TYPES = %w[query update].freeze

  def self.call(payload)
    query_type = payload.keys.first
    query = payload.values.first

    unless QUERY_TYPES.include?(query_type)
      return OpenStruct.new(
        result: {
          error: "Expected either query or update, received #{query_type}"
        },
        status: 400
      )
    end

    response = RestClient::Request.execute(
      method: :post,
      payload: "#{query_type}=#{query}",
      timeout: nil,
      url: ENV.fetch('NEPTUNE_SPARQL_ENDPOINT')
    )

    OpenStruct.new(
      result: JSON(response.body),
      status: response.code
    )
  rescue RestClient::Exception => e
    OpenStruct.new(
      result: e.http_body ? JSON(e.http_body) : { error: e.message },
      status: e.http_code || 500
    )
  end
end
