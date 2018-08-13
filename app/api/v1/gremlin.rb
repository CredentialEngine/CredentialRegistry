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
        response = QueryGremlin.call(env['rack.request.form_vars'])
        status response.status
        response.result
      end
    end
  end
end
