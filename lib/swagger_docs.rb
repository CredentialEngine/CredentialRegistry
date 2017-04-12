require 'swagger_helpers'

module MetadataRegistry
  # Swagger docs definition
  class SwaggerDocs
    include Swagger::Blocks

    swagger_path '/readme' do
      operation :get do
        key :operationId, 'getApi'
        key :description, 'Show the README rendered in HTML'
        key :produces, ['text/html']
        response 200, description: 'shows the README rendered in HTML'
      end
    end

    swagger_path '/' do
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

    swagger_path '/info' do
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

    swagger_path '/schemas/info' do
      operation :get do
        key :operationId, 'getApiSchemasInfo'
        key :description, 'General info about the json-schemas'
        key :produces, ['application/json']

        response 200 do
          key :description, 'General info about the json-schemas'
          schema { key :'$ref', :SchemasInfo }
        end
      end
    end

    swagger_path '/schemas/{schema_name}' do
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
        response 404 do
          key :description, 'No schemas match the schema_name'
        end
      end

      operation :put do
        key :operationId, 'putApiSchema'
        key :description, 'Replace the corresponding json-schema'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter name: :schema_name,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Unique schema name'
        parameter request_envelope

        response 200, description: 'Replaced the corresponding json-schema'
        response 404 do
          key :description, 'No schemas match the schema_name'
        end
      end
    end

    swagger_path '/search' do
      operation :get do
        key :operationId, 'getApiSearch'
        key :description, 'Search envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
        key :produces, ['application/json']

        parameters_for_search

        response 200 do
          key :description, 'Search envelopes'
          schema do
            key :type, :array
            items { key :'$ref', :Envelope }
          end
        end
      end
    end

    swagger_path '/{community_name}/search' do
      operation :get do
        key :operationId, 'getApiCommunitySearch'
        key :description, 'Search by community envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
        key :produces, ['application/json']

        parameter community_name
        parameters_for_search

        response 200 do
          key :description, 'Search by community envelopes'
          schema do
            key :type, :array
            items { key :'$ref', :Envelope }
          end
        end
      end
    end

    swagger_path '/{community_name}/{resource_type}/search' do
      operation :get do
        key :operationId, 'getApiResourceTypeSearch'
        key :description, 'Search by resource_type envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
        key :produces, ['application/json']

        parameter community_name
        parameter name: :resource_type,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Community-specific resource_type'
        parameters_for_search

        response 200 do
          key :description, 'Search by resource_type envelopes'
          schema do
            key :type, :array
            items { key :'$ref', :Envelope }
          end
        end
      end
    end

    swagger_path '/{community_name}' do
      operation :get do
        key :operationId, 'getApiCommunity'
        key :description, 'Retrieve metadata community'
        key :produces, ['application/json']

        parameter community_name

        response 200 do
          key :description, 'Retrieve metadata community'
          schema { key :'$ref', :Community }
        end
      end
    end

    swagger_path '/{community_name}/info' do
      operation :get do
        key :operationId, 'getApiCommunityInfo'
        key :description, 'General info about this metadata community'
        key :produces, ['application/json']

        parameter community_name

        response 200 do
          key :description, 'General info about this metadata community'
          schema { key :'$ref', :CommunityInfo }
        end
      end
    end

    swagger_path '/ce-registry/ctid' do
      operation :get do
        key :operationId, 'getApiCtid'
        key :description, 'Retrieve a new ctid'
        key :produces, ['application/json']

        response 200 do
          key :description, 'Retrieve a new ctid'
          schema { key :'$ref', :Ctid }
        end
      end
    end

    swagger_path '/{community_name}/envelopes' do
      operation :get do
        key :operationId, 'getApiEnvelopes'
        key :description, 'Retrieves all community envelopes ordered by date'
        key :produces, ['application/json']

        parameter community_name
        parameter page_param
        parameter per_page_param
        parameter include_deleted

        response 200 do
          key :description, 'Retrieves all envelopes ordered by date'
          schema do
            key :type, :array
            items { key :'$ref', :Envelope }
          end
        end
      end

      operation :post do
        key :operationId, 'postApiEnvelopes'
        key :description, 'Publishes a new envelope'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter name: :update_if_exists,
                  in: :query,
                  type: :boolean,
                  required: false,
                  description: 'Whether to update the envelope if exists'
        parameter request_envelope

        response 200 do
          key :description, 'Envelope updated'
          schema { key :'$ref', :Envelope }
        end
        response 201 do
          key :description, 'Envelope created'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end

      operation :put do
        key :operationId, 'putApiEnvelopes'
        key :description, 'Marks envelopes as deleted'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter delete_token

        response 204 do
          key :description, 'Matching envelopes marked as deleted'
        end
        response 404 do
          key :description, 'No envelopes match the envelope_id'
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/info' do
      operation :get do
        key :operationId, 'getApiEnvelopesInfo'
        key :description, 'Gives general info about this community envelopes'
        key :produces, ['application/json']

        parameter community_name

        response 200 do
          key :description, 'Gives general info about this community envelopes'
          schema { key :'$ref', :EnvelopesInfo }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/{envelope_id}' do
      operation :get do
        key :operationId, 'getApiSingleEnvelope'
        key :description, 'Retrieves an envelope by identifier'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id
        parameter include_deleted

        response 200 do
          key :description, 'Retrieves an envelope by identifier'
          schema { key :'$ref', :Envelope }
        end
      end

      operation :patch do
        key :operationId, 'patchApiSingleEnvelope'
        key :description, 'Updates an existing envelope'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id
        parameter request_envelope

        response 200 do
          key :description, 'Updates an existing envelope'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end

      operation :delete do
        key :operationId, 'deleteApiSingleEnvelope'
        key :description, 'Marks an existing envelope as deleted'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter delete_token

        response 204 do
          key :description, 'Marks an existing envelope as deleted'
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/{envelope_id}/info' do
      operation :get do
        key :operationId, 'getApiSingleEnvelopeInfo'
        key :description, 'Gives general info about the single envelope'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id
        parameter include_deleted

        response 200 do
          key :description, 'General info about this metadata community'
          schema { key :'$ref', :SingleEnvelopeInfo }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/{envelope_id}'\
                 '/versions/{version_id}' do
      operation :get do
        key :operationId, 'getApiEnvelopeVersion'
        key :description, 'Retrieves a specific envelope version'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id
        parameter include_deleted
        parameter name: :version_id,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Unique version identifier'

        response 200 do
          key :description, 'Retrieves a specific envelope version'
          schema { key :'$ref', :Envelope }
        end
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

    swagger_schema :SchemasInfo do
      property :available_schemas,
               type: :array,
               description: 'List of json-schema URLs available',
               items: { type: :string, description: 'json-schema URL' }
      property :specification,
               type: :string,
               description: 'URL for the json-schema spec'
    end

    swagger_schema :Community do
      property :id,
               type: :integer,
               format: :int32,
               description: 'Community id'
      property :name,
               type: :string,
               description: 'Community name'
      property :backup_item,
               type: :string,
               description: 'Backup item name on Internet Archive'
      property :default,
               type: :boolean,
               description: 'Wether this is the default Community or not'
      property :created_at,
               type: :string,
               format: :'date-time',
               description: 'When the version was created'
      property :updated_at,
               type: :string,
               format: :'date-time',
               description: 'When the version was updated'
    end

    swagger_schema :CommunityInfo do
      property :total_envelopes,
               type: :integer,
               format: :int32,
               description: 'Total count of envelopes for this community'
      property :backup_item,
               type: :string,
               description: 'Internet Archive backup item identifier'
    end

    swagger_schema :EnvelopesInfo do
      property :POST do
        key :description, 'Info for POST requests'
        property :accepted_schemas,
                 description: 'List of accepted_schemas',
                 type: :array,
                 items: { type: :string, description: 'json-schema URL' }
      end
      property :PUT do
        key :description, 'Info for PUT requests'
        property :accepted_schemas,
                 description: 'List of accepted_schemas',
                 type: :array,
                 items: { type: :string, description: 'json-schema URL' }
      end
    end

    swagger_schema :SingleEnvelopeInfo do
      property :PATCH do
        key :description, 'Info for PATCH requests'
        property :accepted_schemas,
                 description: 'List of accepted_schemas',
                 type: :array,
                 items: { type: :string, description: 'json-schema URL' }
      end
      property :DELETE do
        key :description, 'Info for DELETE requests'
        property :accepted_schemas,
                 description: 'List of accepted_schemas',
                 type: :array,
                 items: { type: :string, description: 'json-schema URL' }
      end
    end

    swagger_schema :Envelope do
      key :description, 'Retrieves a specific envelope version'

      property :envelope_id,
               type: :string,
               description: 'Unique identifier (in UUID format)'
      property :envelope_type,
               type: :string,
               description: 'Type ("resource_data" or "paradata")'
      property :envelope_version,
               type: :string,
               description: 'Envelope version used'
      property :resource,
               type: 'string',
               description: 'Resource in its original encoded format'
      property :decoded_resource,
               type: 'string',
               description: 'Resource in decoded form'
      property :resource_format,
               type: 'string',
               description: 'Format of the submitted resource'
      property :resource_encoding,
               type: 'string',
               description: 'Encoding of the submitted resource'
      property :node_headers,
               description: 'Additional headers added by the node',
               '$ref': :NodeHeaders
    end

    swagger_schema :NodeHeaders do
      property :resource_digest,
               type: :string
      property :versions,
               type: :array,
               items: { '$ref': '#/definitions/Version' },
               description: 'Versions belonging to the envelope'
      property :created_at,
               type: :string,
               format: :'date-time',
               description: 'Creation date'
      property :updated_at,
               type: :string,
               format: :'date-time',
               description: 'Last modification date'
      property :deleted_at,
               type: :string,
               format: :'date-time',
               description: 'Deletion date'
    end

    swagger_schema :Version do
      property :head,
               type: :boolean,
               description: 'Tells if it\'s the current version'
      property :event,
               type: :string,
               description: 'What change caused the new version'
      property :created_at,
               type: :string,
               format: :'date-time',
               description: 'When the version was created'
      property :actor,
               type: :string,
               description: 'Who performed the changes'
      property :url,
               type: :string,
               description: 'Version URL'
    end

    swagger_schema :ValidationError do
      property :errors,
               description: 'List of validation error messages',
               type: :array,
               items: { type: :string }
      property :json_schema,
               description: 'List of json-schema\'s used for validation',
               type: :array,
               items: { type: :string, description: 'json-schema URL' }
    end

    swagger_schema :DeleteToken do
      key :description, 'Marks an envelope as deleted'
      property :envelope_id,
               type: :string,
               description: 'Envelope ID'
      property :delete_token,
               type: :string,
               description: 'Any content signed with the user\'s private key'
      property :delete_token_format,
               type: :string,
               description: 'Format of the submitted delete token'
      property :delete_token_encoding,
               type: :string,
               description: 'Encoding of the submitted delete token'
      property :delete_token_public_key,
               type: :string,
               description: 'RSA key in PEM format (same pair used to encode)'

      key :required, [
        :envelope_id,
        :delete_token,
        :delete_token_format,
        :delete_token_encoding,
        :delete_token_public_key
      ]
    end

    swagger_schema :RequestEnvelope do
      key :description, 'Publishes a new envelope'

      property :envelope_id,
               type: :string,
               description: 'Unique identifier (in UUID format)'
      property :envelope_type,
               type: :string,
               description: 'Type ("resource_data" or "paradata")'
      property :envelope_version,
               type: :string,
               description: 'Envelope version used'
      property :resource,
               type: 'string',
               description: 'Resource in its original encoded format'
      property :resource_format,
               type: 'string',
               description: 'Format of the submitted resource'
      property :resource_encoding,
               type: 'string',
               description: 'Encoding of the submitted resource'
      property :resource_public_key,
               type: :string,
               description: 'RSA key in PEM format (same pair used to encode)'

      key :required, [
        :envelope_type,
        :envelope_version,
        :resource,
        :resource_format,
        :resource_public_key
      ]
    end

    swagger_schema :Ctid do
      property :ctid,
               type: :string,
               description: 'Properly formated ctid "urn:ctid:{uuid}"'
    end

    # ==========================================
    # Root Info

    swagger_root do
      key :swagger, '2.0'
      info do
        key :title, 'MetadataRegistry API'
        key :description, 'Documentation for the new API endpoints. '\
                          'You can check more detailed info on: '\
                          'https://github.com/CredentialEngine/CredentialRegistry/blob/master/README.md#docs'
        key :version, 'v1'

        contact name: 'Metadata Registry',
                email: 'learningreg-dev@googlegroups.com',
                url: 'https://github.com/CredentialEngine/CredentialRegistry'

        license name: 'Apache License, Version 2.0',
                url: 'http://www.apache.org/licenses/LICENSE-2.0'
      end
      key :host, 'localhost:9292' # 'lr-staging.learningtapestry.com'
      key :consumes, ['application/json']
      key :produces, ['application/json']
    end
  end
end
