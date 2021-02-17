require 'query_sparql'

module API
  module V1
    # SPARQL endpoint
    class Sparql < Grape::API
      helpers SharedHelpers

      before do
        authenticate!
      end

      desc 'Executes a SPARQL query'
      post '/sparql' do
        params = JSON(request.body.read)
        request.body.rewind
        response = QuerySparql.call(params.symbolize_keys)
        status response.status
        response.result
      end
    end
  end
end
