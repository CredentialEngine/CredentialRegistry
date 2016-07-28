require 'envelope'
require 'entities/envelope'
require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to envelope versions
    class Versions < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers

      resource :versions do
        route_param :version_id, desc: 'The version identifier' do
          desc 'Retrieves a specific envelope version',
               entity: API::Entities::Envelope
          params do
            use :envelope_community
            use :envelope_id
            requires :version_id, desc: 'Unique version identifier'
          end
          get do
            envelope = @envelope.versions.find(params[:version_id]).reify

            present envelope, with: API::Entities::Envelope, is_version: true
          end
        end
      end
    end
  end
end
