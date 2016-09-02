module MetadataRegistry
  # Swagger docs definition
  class SwaggerDocs
    include Swagger::Blocks

    swagger_path '/' do
      operation :get do
        key :operationId, 'getApi'
        key :description, 'Show the README rendered in HTML'
        key :produces, ['text/html']
        response 200, description: 'shows the README rendered in HTML'
      end
    end

    swagger_path '/api' do
      operation :get do
        key :operationId, 'getApi'
        key :description, 'API root'
        key :produces, ['application/json']

        response 200 do
          key :description, 'API root'
          schema { key :'$ref', :ApiRoot }
        end
      end
    end

    swagger_path '/api/info' do
      operation :get do
        key :operationId, 'getApiInfo'
        key :description, 'General info about this API node'
        key :produces, ['application/json']

        response 200 do
          key :description, 'General info about this API node'
          schema { key :'$ref', :ApiInfo }
        end
      end
    end

    swagger_path '/api/schemas/info' do
      operation :get do
        key :operationId, 'getApiSchemasInfo'
        key :description, 'General info about the json-schemas'
        key :produces, ['application/json']

        response 200 do
          key :description, 'General info about the json-schemas'
          schema { key :'$ref', :ApiSchemasInfo }
        end
      end
    end

    swagger_path '/api/schemas/{schema_name}' do
      operation :get do
        key :operationId, 'getApiSchema'
        key :description, 'Get the corresponding json-schema'
        key :produces, ['application/json']

        parameter name: :schema_name,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Unique schema name'

        response 200, description: 'Get the corresponding json-schema'
      end
    end

    # ==========================================
    # Schemas

    swagger_schema :ApiRoot do
      property :api_version,
               type: :string,
               description: 'API version number'
      property :total_envelopes,
               type: :integer,
               format: :int32,
               description: 'Total count of metadata envelopes'
      property :metadata_communities,
               type: :object,
               description: 'Object with community names and their API urls'
      property :info,
               type: :string,
               description: 'URL for the API info'
    end

    swagger_schema :ApiInfo do
      property :metadata_communities,
               type: :object,
               description: 'Object with community names and their API urls'
      property :postman,
               type: :string,
               description: 'URL for the postman collection'
      property :swagger,
               type: :string,
               description: 'URL for the Swagger docs'
      property :readme,
               type: :string,
               description: 'URL for the repo\'s README doc'
      property :docs,
               type: :string,
               description: 'URL for the docs folder'
    end

    swagger_schema :ApiSchemasInfo do
      property :available_schemas,
               type: :array,
               description: 'List of json-schema URLs available',
               items: { type: :string, description: 'json-schema URL' }
      property :specification,
               type: :string,
               description: 'URL for the json-schema spec'
    end

    # ==========================================
    # Root Info

    swagger_root do
      key :swagger, '2.0'
      info do
        key :title, 'MetadataRegistry API'
        key :description, 'Documentation for the new API endpoints'
        key :version, 'v1'

        contact name: 'Metadata Registry',
                email: 'learningreg-dev@googlegroups.com',
                url: 'https://github.com/learningtapestry/metadataregistry'

        license name: 'Apache License, Version 2.0',
                url: 'http://www.apache.org/licenses/LICENSE-2.0'
      end
      key :host, 'localhost:9292' # 'lr-staging.learningtapestry.com'
      key :consumes, ['application/json']
      key :produces, ['application/json']
    end
  end
end
