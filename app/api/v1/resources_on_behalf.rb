require 'services/publish_on_behalf_interactor'

module API
  module V1
    # Default options for all API endpoints and versions
    module ResourcesOnBehalf
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

          params[:envelope_community] = select_community

          interactor = PublishOnBehalfInteractor.call(
            envelope_community: params[:envelope_community],
            organization_id: params[:organization_id],
            current_user: current_user,
            raw_resource: request.body.read
          )

          error!(*interactor.error) if interactor.error

          if interactor.builder_errors
            json_error! interactor.builder_errors,
                        [:envelope, interactor.builder_envelope.try(:resource_schema_name)]
          else
            present interactor.builder_envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          end
        end
      end
    end
  end
end
