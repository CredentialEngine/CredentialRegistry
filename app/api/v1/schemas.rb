require 'helpers/shared_helpers'
require 'schema_config'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers do
        def available_schemas
          SchemaConfig.all_schemas.map do |name|
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
          config = SchemaConfig.new(params[:schema_name])
          unless config.schema_exist?
            error!({ error: ['schema does not exist!'] }, :not_found)
          end

          config.json_schema(request)
        end
      end
    end
  end
end
