require 'mountable_api'
require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'entities/payload_formatter'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'

module API
  module V2
    class Publish < MountableAPI
      mounted do # rubocop:disable Metrics/BlockLength
        helpers SharedHelpers
        helpers CommunityHelpers
        helpers EnvelopeHelpers

        namespace 'resources/organizations/:organization_id/documents' do
          params do
            requires :organization_id, type: String
          end

          before do
            authenticate!

            params[:envelope_community] = select_community
            authenticate_community!

            @organization = Organization.find_by!(_ctid: params[:organization_id])
          end

          desc 'Takes a resource and an organization id, signs the resource '\
               'on behalf of an organization, and publishes a new envelope with '\
               'that signed resource',
               http_codes: [
                 { code: 200, message: 'Envelope creation or update scheduled' }
               ]

          params do
            optional :published_by, type: String
            use :update_if_exists
            use :skip_validation
          end
          post do
            secondary_token_header = request.headers['Secondary-Token']
            secondary_token = if secondary_token_header.present?
                                secondary_token_header.split(' ').last
                              end

            publishing_organization =
              if (published_by = params[:published_by]).present?
                Organization.find_by!(_ctid: params[:published_by])
              end

            publish_request = PublishRequest.schedule(
              envelope_community: select_community,
              organization_id: @organization.id,
              user_id: current_user.id,
              publishing_organization_id: publishing_organization&.id,
              secondary_token: secondary_token,
              raw_resource: request.body.read,
              skip_validation: skip_validation?
            )

            present publish_request, with: API::Entities::PublishRequest
            status(:ok)
          end
        end
      end
    end
  end
end
