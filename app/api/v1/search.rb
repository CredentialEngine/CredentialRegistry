# require 'entities/envelope'
require 'search/document'
require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to search
    class Search < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers

      # params do
      #   use :envelope_community
      # end

      # before_validation do
      #   if params[:envelope_community].present?
      #     params[:envelope_community] = params[:envelope_community].underscore
      #   end
      # end

      resource :search do
        desc 'Search for envelopes', is_array: true
        params do
          use :pagination
        end
        paginate max_per_page: 200
        get do
          options = params.slice(:per_page, :page)
          terms = params.slice(:fts, :filter, :must, :should)
          terms = nil if terms.blank?
          documents = paginate ::Search::Document.search(terms, options)

          present documents.records, with: API::Entities::Envelope
        end
      end
    end
  end
end
