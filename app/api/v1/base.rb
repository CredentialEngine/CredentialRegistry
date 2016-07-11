require 'exceptions'
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

      route_param :envelope_community do
        desc 'Gives general info about the community'
        get do
          community = EnvelopeCommunity.find_by!(
            name: params[:envelope_community].underscore
          )

          {
            total_envelopes: community.envelopes.count,
            backup_item: community.backup_item
          }
        end

        mount API::V1::Envelopes
      end

      desc 'Gives general info about the node'
      get do
        {
          api_version: LR::VERSION,
          total_envelopes: Envelope.count,
          communities: EnvelopeCommunity.pluck(:name).map(&:dasherize),
          postman: 'https://www.getpostman.com/collections/bc38edc491333b643e23',
          swagger: "#{request.scheme}://#{request.host_with_port}/swagger_doc"
        }
      end
    end
  end
end
