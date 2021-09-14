require 'helpers/shared_helpers'
require 'v2/defaults'
require 'v2/publish'
require 'v2/publish_requests'

module API
  module V2
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V2::Defaults
      include Grape::Kaminari

      helpers SharedHelpers
      helpers Pundit

      desc 'used only for testing'
      get(:_test) { test_response }

      mount API::V2::Publish.api_class
      mount API::V2::PublishRequests.api_class

      route_param :community_name do
        mount API::V2::Publish.api_class
      end
    end
  end
end
