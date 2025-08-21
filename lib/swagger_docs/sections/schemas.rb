module MetadataRegistry
  class SwaggerDocs
    module Sections
      module Schemas # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/schemas/info' do
            operation :get do
              key :operationId, 'getApiSchemasInfo'
              key :description, 'General info about the json-schemas'
              key :produces, ['application/json']
              key :tags, ['Schemas']

              security

              response 200 do
                key :description, 'General info about the json-schemas'
                schema { key :$ref, :SchemasInfo }
              end
            end
          end

          swagger_path '/schemas/{schema_name}' do
            operation :get do
              key :operationId, 'getApiSchema'
              key :description, 'Get the corresponding json-schema'
              key :produces, ['application/json']
              key :tags, ['Schemas']

              security

              parameter schema_name

              response 200, description: 'Get the corresponding json-schema'
              response 404 do
                key :description, 'No schemas match the schema_name'
              end
            end

            operation :post do
              key :operationId, 'postApiSchema'
              key :description, 'Creates or updates JSON schemas'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Schemas']

              parameter schema_name

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'JSON schema'
                key :required, true
                schema do
                  key :type, :object
                  key :additionalProperties, true
                end
              end

              response 200, description: 'Updated the existing JSON schema'
              response 201, description: 'Created a new JSON schema'
              response 404 do
                key :description, 'The specified envelope community not found'
              end
            end

            operation :put do
              key :operationId, 'putApiSchema'
              key :description, 'Replace the corresponding json-schema'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Schemas']

              security

              parameter schema_name

              response 200, description: 'Replaced the corresponding json-schema'
              response 404 do
                key :description, 'No schemas match the schema_name'
              end
            end
          end
        end
      end
    end
  end
end
