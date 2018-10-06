require 'helpers/shared_helpers'
require 'services/search'
require 'entities/envelope_resource'

module API
  module V1
    # Implements the endpoints related to search
    class Search < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers do
        # Do the search itself and present the results as a Envelopes list
        def search
          envelopes = paginate MetadataRegistry::Search.new(params).run
          present envelopes, with: API::Entities::EnvelopeResource
        end
      end

      # /search
      desc 'Search for all envelopes', is_array: true
      params { use :pagination }
      get(:search) { search }

      route_param :envelope_community do
        before_validation { normalize_envelope_community }

        # /{community}/search
        desc 'Search for community envelopes', is_array: true
        params do
          use :envelope_community
          use :pagination
        end
        get(:search) { search }

        route_param :resource_type do
          # /{community}/{type}/search
          desc 'Search for community/type envelopes', is_array: true
          params { use :pagination }
          get(:search) { search }
        end
      end
    end
  end
end
