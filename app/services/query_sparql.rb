require 'fetch_description_set_data'
require 'query_log'

# Proxies SPARQL requests to Neptune
class QuerySparql
  ALLOWED_KEYS = %i[query update].freeze

  class << self
    def call(params)
      if params[:log]
        query_log = QueryLog.start(
          ctdl: params[:_ctdl],
          query_logic: params[:_query_logic],
          query: params[:query],
          engine: 'sparql'
        )
      end

      payload = params.slice(*ALLOWED_KEYS)
      uri = URI(ENV.fetch('NEPTUNE_ENDPOINT'))
      uri.path = '/sparql'

      response = RestClient::Request.execute(
        method: :post,
        payload: URI.encode_www_form(payload),
        timeout: nil,
        url: uri.to_s
      )

      result = JSON(response.body)

      if params[:include_description_sets]
        description_set_data = FetchDescriptionSetData.call(
          extract_ctids(result),
          include_resources: params[:include_description_set_resources],
          per_branch_limit: params[:per_branch_limit]
        )

        entity = API::Entities::DescriptionSetData.represent(description_set_data)
        result.merge!(entity.as_json)
      end

      query_log&.complete(result)

      OpenStruct.new(result: result, status: response.code)
    rescue RestClient::Exception => e
      query_log&.fail(e.http_body || e.message)

      OpenStruct.new(
        result: e.http_body ? e.http_body : { error: e.message }.to_json,
        status: e.http_code || 500
      )
    rescue StandardError => e
      query_log&.fail(e.message)
      raise
    end

    private

    def extract_ctids(result)
      if result.is_a?(Array)
        result.map { |item| extract_ctids(item) }.flatten.compact
      elsif result.is_a?(Hash)
        result.map do |key, value|
          key == 'ceterms:ctid' ? [value] : extract_ctids(value)
        end.flatten.compact
      elsif result.is_a?(String)
        begin
          extract_ctids(JSON(result))
        rescue JSON::ParserError
        end
      end
    end
  end
end
