require 'mountable_api'
require 'envelope'
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
require 'v1/envelope_events'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < MountableAPI
      mounted do # rubocop:disable Metrics/BlockLength
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

          desc 'Gives general info about the envelopes'
          get(:info) { envelopes_info }

          include API::V1::EnvelopeEvents

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
