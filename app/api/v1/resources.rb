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
require 'v1/publish'
require 'fetch_envelope_resource'

module API
  module V1
    # Implements all the endpoints related to resources
    class Resources < MountableAPI # rubocop:todo Metrics/ClassLength
      mounted do # rubocop:disable Metrics/BlockLength
        helpers SharedHelpers
        helpers CommunityHelpers
        helpers EnvelopeHelpers

        include API::V1::Defaults
        include API::V1::Publish

        before do
          params[:envelope_community] = select_community
          @envelope_community = EnvelopeCommunity.find_by!(name: select_community)
          @id_field = @envelope_community.id_field
        end

        resource :resources do
          desc 'Publishes a new envelope',
               http_codes: [
                 { code: 201, message: 'Envelope created' },
                 { code: 200, message: 'Envelope updated' }
               ]
          params do
            use :update_if_exists
            use :skip_validation
          end
          post do
            envelope, errors = EnvelopeBuilder.new(
              params,
              update_if_exists: update_if_exists?,
              skip_validation: skip_validation?
            ).build

            if errors
              json_error! errors, [:envelope, envelope.try(:resource_schema_name)]
            else
              present envelope, with: API::Entities::Envelope
              if envelope.created_at == envelope.updated_at
                status(:created)
              else
                status(:ok)
              end
            end
          end

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
            envelope_community = EnvelopeCommunity.find_sole_by(name: community)

            FetchEnvelopeResource
              .new(envelope_community:, resource_id: params[:id])
              .resource
          end

          desc 'Updates an existing envelope'
          params do
            requires :id, type: String, desc: 'Resource id.'
            use :skip_validation
          end
          after_validation do
            find_envelope
          end
          put ':id', requirements: { id: /(.*)/i } do
            sanitized_params = params.dup
            sanitized_params.delete(:id)
            envelope, errors = EnvelopeBuilder.new(
              sanitized_params,
              envelope: @envelope,
              skip_validation: skip_validation?
            ).build

            if errors
              json_error! errors, [:envelope, envelope.try(:community_name)]
            else
              present envelope, with: API::Entities::Envelope
            end
          end

          desc 'Marks an existing envelope as deleted'
          params do
            requires :id, type: String, desc: 'Resource id.'
          end
          after_validation do
            find_envelope
            params[:envelope_id] = @envelope.envelope_id
          end
          delete ':id', requirements: { id: /(.*)/i } do
            validator = JSONSchemaValidator.new(params, :delete_envelope)
            json_error! validator.error_messages, :delete_envelope if validator.invalid?

            BatchDeleteEnvelopes.new([@envelope], DeleteToken.new(params)).run!

            body false
            status :no_content
          end
        end
      end
    end
  end
end
