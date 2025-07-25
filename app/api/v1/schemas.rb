require 'helpers/shared_helpers'
require 'policies/json_schema_policy'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers CommunityHelpers
      helpers SharedHelpers
      helpers do
        def available_schemas
          JsonSchema.pluck(:name).map do |name|
            "#{request.base_url}/schemas/#{name}"
          end
        end
      end

      resource :schemas, requirements: { schema_name: %r{[\w/]+} } do
        desc 'Schemas info'
        get :info do
          {
            available_schemas: available_schemas,
            specification: 'http://json-schema.org/'
          }
        end

        desc 'Retrieves a json-schema by name'
        get ':schema_name' do
          json_schema = JsonSchema.for(params[:schema_name])
          json_schema.public_schema(request)
        rescue MR::SchemaDoesNotExist, name
          error!({ error: ['schema does not exist!'] }, :not_found)
        end

        desc 'Creates or updates a schema'
        post ':schema_name' do
          authenticate!

          authorize JsonSchema, :create?

          unless params[:envelope_community]
            params[:envelope_community] = params[:schema_name].split('/').first
          end

          EnvelopeCommunity.find_by!(name: params[:envelope_community])

          schema = JsonSchema.find_or_initialize_by(name: params[:schema_name])
          status schema.new_record? ? 201 : 200
          schema.update!(schema: JSON(request.body.read))
          schema.schema
        end

        desc 'Updates a schema'
        before do
          unless params[:envelope_community]
            params[:envelope_community] = params[:schema_name].split('/').first
          end
        end
        put ':schema_name' do
          builder = EnvelopeBuilder.new(params)
          json_schema = JsonSchema.for(params[:schema_name])

          if builder.validate
            schema = builder.envelope.processed_resource['schema']
            json_schema.update(schema: schema)
            status(:ok)
          else
            json_error! builder.errors,
                        [:envelope,
                         builder.envelope.try(:resource_schema_name)],
                        :not_found
          end
        rescue MR::SchemaDoesNotExist
          error!({ error: ['schema does not exist!'] }, :not_found)
        end
      end
    end
  end
end
