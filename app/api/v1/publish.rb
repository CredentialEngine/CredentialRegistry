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
          secondary_token = if secondary_token_header.present?
                              secondary_token_header.split(' ').last
                            end

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

        # we need the 'requirements' param since the ctid can look like a url,
        # including periods, and we don't want grape interpreting that as a
        # format specifier

        delete 'resources/organizations/:organization_id/documents/:ctid',
               requirements: { ctid: /.*/ } do

          authenticate!

          publisher = current_user.publisher
          organization = Organization.find(params[:organization_id])

          if publisher.authorized_to_publish?(organization)
            envelope = Envelope
                       .not_deleted
                       .where(organization_id: params[:organization_id])
                       .where(publisher_id: current_user.publisher.id)
                       .where('processed_resource ->> \'ceterms:ctid\' = ?', params[:ctid])
                       .first

            if envelope
              envelope.mark_as_deleted!
              body ''
            else
              json_error!([Envelope::NOT_FOUND], nil, 404)
            end
          else
            json_error!([Publisher::NOT_AUTHORIZED_TO_PUBLISH], nil, 401)
          end
        end
      end
    end
  end
end
