# require 'entities/envelope'
require 'search/document'
require 'helpers/shared_helpers'
require 'v1/search_helpers'

module API
  module V1
    # Implements all the endpoints related to search
    class Search < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers SearchHelpers
      helpers do
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
