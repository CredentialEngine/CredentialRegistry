require 'envelope'
require 'entities/envelope'
require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to envelope revisions
    class Revisions < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers

      resource :revisions do
        route_param :revision_id, desc: 'The revision identifier' do
          desc 'Retrieves a specific envelope version',
               entity: API::Entities::Envelope
          params do
            use :envelope_community
            use :envelope_id
            requires :revision_id, desc: 'Unique revision identifier'
          end
          get do
            envelope = @envelope.versions.find(params[:revision_id]).reify

            present envelope, with: API::Entities::Envelope, is_version: true
          end
        end
      end
    end
  end
end
