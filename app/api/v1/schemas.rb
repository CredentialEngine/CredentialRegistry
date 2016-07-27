require 'helpers/shared_params'
require 'json_schema'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers SharedParams
      helpers do
        def available_schemas
          JSONSchema.all_schemas.map do |name|
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
          json_schema = JSONSchema.new(params[:schema_name])
          unless json_schema.exist?
            error!({ error: ['schema does not exist!'] }, :not_found)
          end

          json_schema.public_schema(request)
        end
      end
    end
  end
end
