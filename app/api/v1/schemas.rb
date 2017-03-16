require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers do
        def available_schemas
          JsonSchema.pluck(:name).map do |name|
            "#{request.base_url}/api/schemas/#{name}"
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
          begin
            json_schema = JsonSchema.for(params[:schema_name])
            json_schema.public_schema(request)
          rescue MR::SchemaDoesNotExist, name
            error!({ error: ['schema does not exist!'] }, :not_found)
          end
        end

        desc 'Updates a schema'
        before do
          unless params[:envelope_community]
            params[:envelope_community] = params[:schema_name].split('/').first
          end
        end
        put ':schema_name' do
          builder = EnvelopeBuilder.new(params)

          if builder.validate
            schema = builder.envelope.processed_resource['schema']
            JsonSchema.for(params[:schema_name]).update(schema: schema)
            status(:ok)
          else
            json_error! errors, [:envelope, envelope.try(:resource_schema_name)]
          end
        end
      end
    end
  end
end
