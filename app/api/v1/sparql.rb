require 'query_sparql'

module API
  module V1
    # SPARQL endpoint
    class Sparql < Grape::API
      content_type :txt, 'text/plain'
      format :txt
      helpers SharedHelpers

      before do
        authenticate!
      end

      desc 'Executes a SPARQL query'
      post '/sparql' do
        payload = JSON(request.body.read)
        request.body.rewind
        response = QuerySparql.call(payload)
        content_type 'text/plain' if response.result.is_a?(String)
        status response.status
        response.result
      end
    end
  end
end
