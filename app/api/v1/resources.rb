require 'mountable_api'
require 'envelope'
require 'envelope_builder'
require 'entities/envelope'
require 'entities/payload_formatter'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'
require 'v1/publish'
require 'fetch_envelope_resource'

module API
  module V1
    # Implements all the endpoints related to resources
    class Resources < MountableAPI
      mounted do # rubocop:disable Metrics/BlockLength
        helpers SharedHelpers
        helpers CommunityHelpers
        helpers EnvelopeHelpers

        include API::V1::Publish

        before do
          params[:envelope_community] = select_community
          @envelope_community = EnvelopeCommunity.find_by!(name: select_community)
          @id_field = @envelope_community.id_field
        end

        resource :resources do
          desc 'Returns CTIDs of existing resources'
          params do
            requires :ctids, type: [String], desc: 'CTIDs'
          end
          post 'check_existence' do
            status(:ok)

            id_field = "envelope_resources.processed_resource->>'#{@id_field}'"

            @envelope_community
              .envelope_resources
              .not_deleted
              .where("#{id_field} IN (?)", params[:ctids])
              .pluck(Arel.sql(id_field))
          end

          desc 'Returns resources with the given CTIDs or bnodes IDs'
          params do
            optional :bnodes, type: [String], desc: 'Bnodes IDs'
            optional :ctids, type: [String], desc: 'CTIDs'
          end
          post 'search' do
            status(:ok)

            Envelope
              # rubocop:todo Layout/LineLength
              .joins("CROSS JOIN LATERAL jsonb_array_elements(processed_resource->'@graph') AS graph(resource)")
              # rubocop:enable Layout/LineLength
              .where(deleted_at: nil)
              .where(
                "graph.resource->>'@id' IN (?) OR graph.resource->>'#{@id_field}' IN (?)",
                params[:bnodes],
                params[:ctids]
              )
              .pluck('graph.resource')
              .map { |r| JSON(r) }
          end

          desc 'Return a resource.'
          params do
            requires :id, type: String, desc: 'Resource id.'
          end
          before do
            authenticate_community!
          end
          get ':id', requirements: { id: /(.*)/i } do
            begin
              find_envelope
            rescue ActiveRecord::RecordNotFound
              raise ActiveRecord::RecordNotFound, "Couldn't find Resource"
            end

            resource = FetchEnvelopeResource
                       .new(
                         envelope_community: current_community,
                         resource_id: params[:id]
                       )
                       .resource

            resource || present(PayloadFormatter.format_payload(
                                  @envelope.inner_resource_from_graph(params[:id])
                                ))
          end
        end
      end
    end
  end
end
