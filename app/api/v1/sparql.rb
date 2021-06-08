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
      params do
        optional :log, default: true, type: Boolean
      end
      post '/sparql' do
        response = QuerySparql.call(params.symbolize_keys)
        status response.status
        response.result
      end
    end
  end
end
