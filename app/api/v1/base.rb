require 'exceptions'
require 'v1/defaults'
require 'v1/envelopes'
require 'v1/schemas'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V1::Defaults

      mount API::V1::Envelopes.anonymous_class
      mount API::V1::Schemas.anonymous_class

      route_param :envelope_community do
        mount API::V1::Envelopes.anonymous_class
      end
    end
  end
end
