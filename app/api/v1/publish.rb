require 'services/publish_interactor'

module API
  module V1
    # Default options for all API endpoints and versions
    module Publish
      extend ActiveSupport::Concern

      included do
        desc 'Takes a resource and an organization id, signs the resource '\
             'on behalf of an organization, and publishes a new envelope with '\
             'that signed resource',
             http_codes: [
               { code: 201, message: 'Envelope created' },
               { code: 200, message: 'Envelope updated' }
             ]

        params do
          use :update_if_exists
          use :skip_validation
        end

        post 'resources/organizations/:organization_id/documents' do
          authenticate!

          secondary_token_header = request.headers['Secondary-Token']
          secondary_token =
            secondary_token_header.present? && secondary_token_header.split(' ').last

          interactor = PublishInteractor.call(
            envelope_community: select_community,
            organization_id: params[:organization_id],
            secondary_token: secondary_token,
            current_user: current_user,
            raw_resource: request.body.read
          )

          if interactor.success?
            present interactor.envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          else
            json_error!([interactor.error.first], nil, interactor.error.last)
          end
        end
      end
    end
  end
end
