require 'envelope'
require 'entities/envelope'
require 'helpers/shared_params'

module API
  module V1
    # Implements all the endpoints related to envelope versions
    class Versions < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :versions do
        route_param :version_id do
          desc 'Retrieves a specific envelope version',
               entity: API::Entities::Envelope
          get do
            envelope = @envelope.versions.find(params[:version_id]).reify

            present envelope, with: API::Entities::Envelope, is_version: true
          end
        end
      end
    end
  end
end
