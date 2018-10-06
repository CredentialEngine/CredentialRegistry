require 'helpers/shared_helpers'
require 'v1/defaults'
require 'v1/home'
require 'v1/root'
require 'v1/schemas'
require 'v1/search'
require 'v1/ce_registry'
require 'v1/resources'
require 'v1/envelopes'
require 'v1/publishers'
require 'v1/organizations'
require 'v1/graph'
require 'v1/gremlin'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers Pundit

      desc 'used only for testing'
      get(:_test) { test_response }

      mount API::V1::Home
      mount API::V1::Root
      mount API::V1::Schemas
      mount API::V1::Search
      mount API::V1::CERegistry
      mount API::V1::Resources
      mount API::V1::Resources.api_class
      mount API::V1::Envelopes.api_class
      mount API::V1::Envelopes
      mount API::V1::Graph
      mount API::V1::Graph.api_class
      mount API::V1::Gremlin

      route_param :community_name do
        mount API::V1::Resources.api_class
        mount API::V1::Envelopes.api_class
        mount API::V1::Graph.api_class
      end

      namespace :metadata do
        rescue_from ActiveRecord::RecordInvalid do |e|
          error!(e.record.errors.full_messages.first, 422)
        end

        rescue_from Pundit::NotAuthorizedError do
          error!('You are not authorized to perform this action', 403)
        end

        mount API::V1::Organizations
        mount API::V1::Publishers
      end

      namespace :metadata do
        rescue_from ActiveRecord::RecordInvalid do |e|
          error!(e.record.errors.full_messages.first, 422)
        end

        rescue_from Pundit::NotAuthorizedError do
          error!('You are not authorized to perform this action', 403)
        end

        mount API::V1::Organizations
        mount API::V1::Publishers
      end
    end
  end
end
