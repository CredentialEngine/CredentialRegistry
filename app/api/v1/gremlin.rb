require 'exceptions'
require 'v1/defaults'
require 'v1/envelopes'
require 'query_gremlin'

module API
  module V1
    # Gremlin endpoint
    class Gremlin < Grape::API
      helpers SharedHelpers

      desc 'Executes a Gremlin query'
      before do
        authenticate!
      end
      post '/gremlin' do
        payload = request.body.read
        request.body.rewind
        response = QueryGremlin.call(payload)
        status response.status
        response.result
      end
    end
  end
end
