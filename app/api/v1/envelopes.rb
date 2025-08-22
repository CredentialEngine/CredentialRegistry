require 'mountable_api'
require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'envelope_download'
require 'entities/envelope'
require 'entities/envelope_download'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'
require 'policies/envelope_policy'
require 'v1/single_envelope'
require 'v1/revisions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < MountableAPI # rubocop:todo Metrics/ClassLength
      mounted do # rubocop:disable Metrics/BlockLength
        include API::V1::Defaults

        helpers SharedHelpers
        helpers EnvelopeHelpers
        helpers CommunityHelpers

        before do
          params[:envelope_community] = select_community if params[:envelope_community].blank?
        end

        before_validation { normalize_envelope_community }

        desc 'Show metadata community'
        get 'community' do
          EnvelopeCommunity.find_by!(name: community).as_json
        end

        desc 'Gives general info about the community'
        get 'community/info' do
          comm = EnvelopeCommunity.find_by!(name: community)
          {
            total_envelopes: comm.envelopes.count,
            backup_item: comm.backup_item
          }
        end

        resource :envelopes do
          desc 'Retrieves all envelopes ordered by date', is_array: true
          params do
            use :metadata_only
            use :pagination
            use :provisional
          end
          paginate max_per_page: 200
          get do
            authenticate_community!
            envelopes = paginate(
              find_envelopes
                .ordered_by_date
                .with_provisional_publication_status(params[:provisional])
            )

            present envelopes,
                    with: API::Entities::Envelope,
                    type: params[:metadata_only] ? :metadata_only : :full
          end

          desc 'Publishes a new envelope',
               http_codes: [
                 { code: 201, message: 'Envelope created' },
                 { code: 200, message: 'Envelope updated' }
               ]
          params do
            optional :owned_by, type: String
            optional :published_by, type: String
            use :update_if_exists
            use :skip_validation
          end
          post do
            if (owned_by = params[:owned_by]).present?
              params[:organization_id] = Organization.find_by!(_ctid: owned_by).id
            end

            if (published_by = params[:published_by]).present?
              params[:publishing_organization_id] = Organization
                                                    .find_by!(_ctid: published_by)
                                                    .id
            end

            envelope, errors = EnvelopeBuilder.new(
              params,
              update_if_exists: update_if_exists?,
              skip_validation: skip_validation?
            ).build

            if errors
              json_error! errors, [:envelope, envelope.try(:resource_schema_name), :json_ld]
            else
              present envelope, with: API::Entities::Envelope
              update_if_exists? ? status(:ok) : status(:created)
            end
          end

          desc 'Marks envelopes matching a resource locator as deleted'
          helpers do
            def find_community_envelopes
              envelopes = find_envelopes.where(envelope_id: params[:envelope_id])
              if envelopes.empty?
                err = ['No matching envelopes found']
                json_error! err, :delete_envelope, :not_found
              end
              envelopes
            end
          end
          put do
            envelopes = find_community_envelopes
            BatchDeleteEnvelopes.new(envelopes, DeleteToken.new(params)).run!

            body false
            status :no_content
          end

          desc 'Gives general info about the envelopes'
          get(:info) { envelopes_info }

          route_param :envelope_id do
            after_validation do
              id = params[:envelope_id]&.downcase

              @envelope = find_envelopes.find_by(envelope_id: id) ||
                          find_envelopes.where(envelope_ceterms_ctid: id).last ||
                          find_envelopes
                          .joins(:envelope_resources)
                          .where(envelope_resources: { resource_id: id })
                          .last

              if id.starts_with?('_:') || @envelope.nil?
                error!({ errors: ['Couldn\'t find Envelope'] }, 404)
              end
            end

            include API::V1::SingleEnvelope
            include API::V1::Revisions
          end

          resources :downloads do
            before do
              authenticate!
            end

            desc 'Returns the download object with the given ID'
            get ':id' do
              authorize Envelope, :index?

              envelope_download = current_user_community.envelope_downloads.find(params[:id])
              present envelope_download, with: API::Entities::EnvelopeDownload
            end

            desc 'Starts new envelope download'
            post do
              authorize Envelope, :index?

              present current_user_community.envelope_downloads.create!,
                      with: API::Entities::EnvelopeDownload
            end
          end
        end
      end
    end
  end
end
