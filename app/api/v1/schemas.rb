require 'learning_registry_metadata'
require 'helpers/shared_params'
require 'json_schema_validator'

module API
  module V1
    # Implements all the endpoints related to schemas
    class Schemas < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :schemas do
        route_param :schema_name do
          desc 'Retrieves a json-schema by name'
          get do
            validator = JSONSchemaValidator.new(nil, params[:schema_name])
            unless validator.schema_exist?
              error!({ error: ['schema does not exist!'] }, :not_found)
            end

            validator.public_schema(request)
          end
        end
      end
    end
  end
end
