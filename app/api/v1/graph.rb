require 'mountable_api'
require 'envelope'
require 'envelope_builder'
require 'entities/envelope'
require 'entities/payload_formatter'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'
require 'v1/publish'

module API
  module V1
    # Implements all the endpoints related to resources
    class Graph < MountableAPI
      mounted do # rubocop:todo Metrics/BlockLength
        helpers SharedHelpers
        helpers CommunityHelpers
        helpers EnvelopeHelpers

        include API::V1::Publish

        before do
          params[:envelope_community] = select_community
          authenticate_community!
        end

        resource :graph do
          namespace do
            desc 'Return a resource. ' \
                 'If the resource is part of a graph, the entire graph is returned.'
            params do
              requires :id, type: String, desc: 'Resource id.'
            end
            after_validation do
              find_envelope
            end
            get ':id', requirements: { id: /(.*)/i } do
              present PayloadFormatter.format_payload(@envelope.processed_resource)
            end
          end

          desc 'Returns graphs with the given CTIDs'
          params do
            requires :ctids, type: [String], desc: 'CTIDs'
          end
          post :search do
            status(:ok)

            ctids = params[:ctids]&.map(&:downcase)

            find_envelopes
              .where(envelope_ceterms_ctid: ctids)
              .pluck(:processed_resource)
          end
        end
      end
    end
  end
end
