require 'helpers/shared_helpers'
require 'v1/defaults'
require 'v1/home'
require 'v1/root'
require 'v1/schemas'
require 'v1/search'
require 'v1/ce_registry'
require 'v1/resources_api'
require 'v1/resources'
require 'v1/envelopes'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers

      desc 'used only for testing'
      get(:_test) { test_response }

      mount API::V1::Home
      mount API::V1::Root
      mount API::V1::Schemas
      mount API::V1::Search
      mount API::V1::CERegistry
      mount API::V1::Resources

      route_param :envelope_community do
        mount API::V1::Envelopes
      end
    end
  end
end
