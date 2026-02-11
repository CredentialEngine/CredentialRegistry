require 'defaults'
require 'helpers/shared_helpers'
require 'v1/home'
require 'v1/root'
require 'v1/search'
require 'v1/ce_registry'
require 'v1/resources'
require 'v1/envelopes'
require 'v1/publishers'
require 'v1/organizations'
require 'v1/graph'
require 'v1/description_sets'
require 'v1/config'
require 'v1/bulk_purge'
require 'v1/ctdl'
require 'v1/json_contexts'
require 'v1/indexed_resources'
require 'v1/indexer'
require 'v1/envelope_communities'
require 'v1/workflows'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::Defaults
      include Grape::Kaminari

      helpers SharedHelpers
      helpers Pundit::Authorization

      version 'v1', using: :accept_version_header

      desc 'used only for testing'
      get(:_test) { test_response }

      mount API::V1::Home
      mount API::V1::Root
      mount API::V1::Search
      mount API::V1::CERegistry
      mount API::V1::Resources.api_class
      mount API::V1::Envelopes.api_class
      mount API::V1::Graph.api_class
      mount API::V1::DescriptionSets.api_class
      mount API::V1::BulkPurge.api_class
      mount API::V1::Ctdl.api_class
      mount API::V1::IndexedResources.api_class
      mount API::V1::Indexer.api_class

      route_param :community_name do
        mount API::V1::Resources.api_class
        mount API::V1::Envelopes.api_class
        mount API::V1::Graph.api_class
        mount API::V1::DescriptionSets.api_class
        mount API::V1::BulkPurge.api_class
        mount API::V1::Ctdl.api_class
        mount API::V1::IndexedResources.api_class
        mount API::V1::Indexer.api_class
      end

      namespace :metadata do
        mount API::V1::Config
        mount API::V1::EnvelopeCommunities
        mount API::V1::JsonContexts
        mount API::V1::Organizations
        mount API::V1::Publishers
      end

      mount API::V1::Workflows
    end
  end
end
