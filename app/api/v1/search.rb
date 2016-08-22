require 'search/document'
require 'helpers/shared_helpers'
require 'v1/search_helpers'

module API
  module V1
    # Implements the endpoints related to search
    class Search < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers SearchHelpers
      helpers do
        # Do the search itself and present the results as a Envelopes list
        def search
          docs = paginate ::Search::Document.search(search_terms, search_pagn)
          present docs.records, with: API::Entities::Envelope
        end
      end

      # /api/search
      desc 'Search for all envelopes', is_array: true
      params { use :pagination }
      get(:search) { search }

      route_param :envelope_community do
        before_validation { normalize_envelope_community }

        # /api/{community}/search
        desc 'Search for community envelopes', is_array: true
        params do
          use :envelope_community
          use :pagination
        end
        get(:search) { search }

        route_param :resource_type do
          # /api/{community}/{type}/search
          desc 'Search for community/type envelopes', is_array: true
          params { use :pagination }
          get(:search) { search }
        end
      end
    end
  end
end
