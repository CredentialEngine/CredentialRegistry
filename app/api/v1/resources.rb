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
        end

        resource :resources do
          desc 'Returns CTIDs of existing resources'
          params do
            requires :ctids, type: [String], desc: 'CTIDs'
            optional :@type, type: String, desc: 'Resource type'
          end
          post 'check_existence' do
            status(:ok)

            resource_types =
              if (type = params[:@type]).present?
                resolver = CtdlSubclassesResolver.new(envelope_community: @envelope_community)

                unless resolver.all_classes.include?(type)
                  error!(
                    { errors: ['@type does not have a valid value'] },
                    :unprocessable_entity
                  )
                end

                resolver.root_class = type

                resolver.subclasses.filter_map do |subclass|
                  @envelope_community
                    .config
                    .dig('resource_type', 'values_map', subclass)
                end
              end

            envelope_resources = @envelope_community
                                 .envelope_resources
                                 .not_deleted
                                 .where('resource_id IN (?)', params[:ctids])

            envelope_resources.where!(resource_type: resource_types.uniq) unless resource_types.nil?

            envelope_resources.pluck(:resource_id)
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
                # rubocop:todo Layout/LineLength
                "graph.resource->>'@id' IN (?) OR graph.resource->>'#{@envelope_community.id_field}' IN (?)",
                # rubocop:enable Layout/LineLength
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
            resource = FetchEnvelopeResource
                       .new(
                         envelope_community: current_community,
                         resource_id: params[:id]
                       )
                       .resource

            return resource if resource

            begin
              find_envelope

              present(PayloadFormatter.format_payload(
                        @envelope.inner_resource_from_graph(params[:id])
                      ))
            rescue ActiveRecord::RecordNotFound
              raise ActiveRecord::RecordNotFound.new(nil, 'Resource')
            end
          end
        end
      end
    end
  end
end
