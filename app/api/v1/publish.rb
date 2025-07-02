require 'policies/envelope_policy'
require 'services/publish_interactor'

module API
  module V1
    # Default options for all API endpoints and versions
    module Publish # rubocop:todo Metrics/ModuleLength
      extend ActiveSupport::Concern

      included do
        namespace 'resources' do
          before do
            authenticate!
          end

          namespace 'organizations/:organization_id/documents' do
            params do
              requires :organization_id, type: String
            end

            before do
              @organization = Organization.find_by!(_ctid: params[:organization_id])
            end

            desc 'Takes a resource and an organization id, signs the resource ' \
                 'on behalf of an organization, and publishes a new envelope with ' \
                 'that signed resource',
                 http_codes: [
                   { code: 201, message: 'Envelope created' },
                   { code: 200, message: 'Envelope updated' }
                 ]

            params do
              optional :published_by, type: String
              use :update_if_exists
              use :skip_validation
            end
            post do # rubocop:todo Metrics/BlockLength
              authorize Envelope, :create?

              secondary_token_header = request.headers['Secondary-Token']
              secondary_token = if secondary_token_header.present?
                                  secondary_token_header.split.last
                                end

              publishing_organization =
                if params[:published_by].present?
                  Organization.find_by!(_ctid: params[:published_by])
                end

              resource_publish_type = params[:resource_publish_type] || 'primary'

              interactor = PublishInteractor.call(
                envelope_community: select_community,
                organization: @organization,
                publishing_organization: publishing_organization,
                resource_publish_type: resource_publish_type,
                secondary_token: secondary_token,
                current_user: current_user,
                raw_resource: request.body.read,
                skip_validation: skip_validation?
              )

              if interactor.success?
                present interactor.envelope, with: API::Entities::Envelope
                update_if_exists? ? status(:ok) : status(:created)
              else
                json_error!([interactor.error.first], nil, interactor.error.last)
              end
            end
          end

          namespace 'documents/:ctid' do
            params do
              # we need the 'regexp' param since the ctid can look like a url,
              # including periods, and we don't want grape interpreting that as a
              # format specifier
              requires :ctid, regexp: /\A.+\z/, type: String
            end

            before do
              @publisher = current_user.publisher

              @envelope = Envelope
                          .in_community(select_community)
                          .not_deleted
                          .where(envelope_ceterms_ctid: params[:ctid]&.downcase)
                          .first

              json_error!([Envelope::NOT_FOUND], nil, 404) unless @envelope
            end

            desc 'Deletes the envelope with a given CTID'
            delete do
              authorize Envelope, :destroy?
              @envelope.destroy
              body ''
            end

            desc 'Transfers ownership of the envelope with a given CTID ' \
                 'to the organization with a given ID'
            params do
              requires :organization_id, type: String
            end
            patch 'transfer' do
              authorize Envelope, :update?

              unless @publisher.super_publisher?
                json_error!([Publisher::NOT_AUTHORIZED_TO_PUBLISH], nil, 401)
              end

              organization = Organization.find(params[:organization_id])

              interactor = PublishInteractor.call(
                envelope: @envelope,
                envelope_community: select_community,
                organization: organization,
                current_user: current_user,
                skip_validation: true
              )

              if interactor.success?
                present interactor.envelope, with: API::Entities::Envelope
              else
                error_message, error_code = interactor.error
                json_error!([error_message], nil, error_code)
              end
            end
          end
        end
      end
    end
  end
end
