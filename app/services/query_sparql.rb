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

    params = "#{query_type}=#{query}"
    response = RestClient.post(ENV.fetch('NEPTUNE_SPARQL_ENDPOINT'), params)

    OpenStruct.new(
      result: JSON(response.body),
      status: response.code
    )
  rescue RestClient::Exception => e
    OpenStruct.new(
      result: JSON(e.http_body),
      status: e.http_code
    )
  end
end
