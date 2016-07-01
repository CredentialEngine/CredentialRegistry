require 'learning_registry_metadata'
require 'helpers/shared_params'
require 'json_schema'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :schemas, requirements: { schema_name: %r{[\w/]+} } do
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
