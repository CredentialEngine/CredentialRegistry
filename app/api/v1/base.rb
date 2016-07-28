require 'exceptions'
require 'helpers/shared_helpers'
require 'v1/defaults'
require 'v1/envelopes'
require 'v1/schemas'
require 'v1/home'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V1::Defaults

      mount API::V1::Home
      mount API::V1::Schemas

      helpers SharedHelpers
      helpers do
        def metadata_communities
          communities = EnvelopeCommunity.pluck(:name).flat_map do |name|
            [name, url(:api, name.dasherize)]
          end
          Hash[*communities]
        end
      end

      desc 'api root'
      get do
        {
          api_version: LR::VERSION,
          total_envelopes: Envelope.count,
          metadata_communities: metadata_communities,
          info: url(:api, :info)
        }
      end

      desc 'Gives general info about the node'
      get :info do
        {
          metadata_communities: metadata_communities,
          postman: 'https://www.getpostman.com/collections/bc38edc491333b643e23',
          swagger: url(:swagger_doc),
          readme: 'https://github.com/learningtapestry/metadataregistry/blob/master/README.md',
          docs: 'https://github.com/learningtapestry/metadataregistry/tree/master/docs'
        }
      end

      route_param :envelope_community do
        desc 'Gives general info about the community'
        get :info do
          comm = EnvelopeCommunity.find_by!(
            name: params[:envelope_community].underscore
          )
          {
            total_envelopes: comm.envelopes.count,
            backup_item: comm.backup_item
          }
        end

        mount API::V1::Envelopes
      end
    end
  end
end
