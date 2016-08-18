# require 'entities/envelope'
require 'search/document'
require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to search
    class Search < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers do
        def search_filters
          filters = {
            community: community || params[:community]
          }.compact
          filters.blank? ? nil : filters
        end

        def search_terms
          terms = {
            fts: params[:fts],
            filter: search_filters
          }.compact
          terms.blank? ? nil : terms
        end

        def search_pagn
          params.slice(:per_page, :page)
        end

        def search
          docs = paginate ::Search::Document.search(search_terms, search_pagn)
          present docs.records, with: API::Entities::Envelope
        end
      end

      params { use :pagination }

      desc 'Search for envelopes', is_array: true
      get(:search) { search }

      route_param :envelope_community do
        params { use :envelope_community }
        before_validation { normalize_envelope_community }

        desc 'Search for envelopes', is_array: true
        get(:search) { search }
      end
    end
  end
end
