require 'swagger_helpers'

module MetadataRegistry
  # Swagger docs definition
  class SwaggerDocs
    include Swagger::Blocks

    swagger_path '/readme' do
      operation :get do
        key :operationId, 'getReadme'
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

        parameter schema_name

        response 200, description: 'Replaced the corresponding json-schema'
        response 404 do
          key :description, 'No schemas match the schema_name'
        end
      end
    end

    swagger_path '/graph/{resource_id}' do
      operation :get do
        key :operationId, 'getApiResourceGraph'
        key :description, 'Retrieves a resource by identifier. If the resource' \
                          'is part of a graph, the entire graph is returned.'
        key :produces, ['application/json']

        parameter resource_id

        response 200 do
          key :description, 'Retrieves a resource by identifier'
          schema do
            key :description, 'Refer to the JSON Schema of your desired ' \
                              'community for the resource specification.'
            key :type, :object
          end
        end
      end
    end

    swagger_path '/graph/search' do
      operation :post do
        key :operationId, 'postApiGraphSearch'
        key :description, 'Retrieves graphs by the given CTIDs'
        key :produces, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'JSON object containing array of CTIDs'
          key :required, true

          schema do
            key :type, :object
            key :required, [:ctids]

            property :ctids do
              key :type, :array
              key :description, 'Array of CTIDs'

              items do
                key :type, :string
              end
            end
          end
        end

        response 200 do
          key :description, 'Array of graphs with the given CTIDs'

          schema do
            key :type, :array
            items do
              key :$ref, :Graph
            end
          end
        end
      end
    end

    swagger_path '/resources' do
      operation :post do
        key :operationId, 'postApiSingleResource'
        key :description, 'Publishes a new resource'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter name: :update_if_exists,
                  in: :query,
                  type: :boolean,
                  required: false,
                  description: 'Whether to update the resource if exists'
        parameter request_envelope

        response 200 do
          key :description, 'Resource updated'
          schema { key :'$ref', :Envelope }
        end
        response 201 do
          key :description, 'Resource created'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end
    end

    swagger_path '/resources/check_existence' do
      operation :post do
        key :operationId, 'postApiResourceCheckExistence'
        key :description, 'Returns existing CTIDs'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'JSON object containing array of CTIDs'
          key :required, true

          schema do
            key :type, :object
            key :required, [:ctids]

            property :ctids do
              key :type, :array
              key :description, 'Array of CTIDs'

              items do
                key :type, :string
              end
            end
          end
        end

        response 200 do
          key :description, 'Array of existing CTIDs'

          schema do
            key :type, :array
            items do
              key :type, :string
            end
          end
        end
      end
    end

    swagger_path '/resources/search' do
      operation :post do
        key :operationId, 'postApiResourceSearch'
        key :description, 'Returns resources with the given CTIDs or bnode IDs'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'JSON object containing bnodes and/or CTIDs'
          key :required, true

          schema do
            key :type, :object

            property :bnodes do
              key :type, :array
              key :description, 'Array of bnodes'

              items do
                key :type, :string
              end
            end

            property :ctids do
              key :type, :array
              key :description, 'Array of CTIDs'

              items do
                key :type, :string
              end
            end
          end
        end

        response 200 do
          key :description,
              'Array of resources with the given CTIDs or bnode IDs'

          schema do
            key :type, :array
            items do
              key :$ref, :Resource
            end
          end
        end
      end
    end

    swagger_path '/resources/{resource_id}' do
      operation :get do
        key :operationId, 'getApiSingleResource'
        key :description, 'Retrieves a resource by identifier'
        key :produces, ['application/json']

        parameter resource_id

        response 200 do
          key :description, 'Retrieves a resource by identifier'
          schema do
            key :description, 'Refer to the JSON Schema of your desired ' \
                              'community for the resource specification.'
            key :type, :object
          end
        end
      end

      operation :put do
        key :operationId, 'putApiSingleResource'
        key :description, 'Updates a single resource'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter resource_id
        parameter request_envelope

        response 200 do
          key :description, 'Resource updated'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end

      operation :delete do
        key :operationId, 'deleteApiSingleResource'
        key :description, 'Marks an existing resource as deleted'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter resource_id
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
        parameter resource_type(_in: :path)
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
        parameter metadata_only
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
        parameter name: :owned_by,
                  in: :query,
                  type: :string,
                  required: false,
                  description: 'The CTID of the owning organization'
        parameter published_by
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
        parameter delete_envelope_token

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

      operation :delete do
        key :operationId, 'deleteEnvelopes'
        key :description, 'Purges envelopes published by the given publisher'
        key :produces, ['application/json']

        parameter community_name
        parameter published_by(required: true)
        parameter resource_type
        parameter name: :from,
                  in: :query,
                  type: :string,
                  required: false,
                  description: 'Datetime after which envelopes were publisher'
        parameter name: :until,
                  in: :query,
                  type: :string,
                  required: false,
                  description: 'Datetime before which envelopes were publisher'

        response 204 do
          key :description, 'Successfully purged selected envelopes'
        end
      end
    end

    swagger_path '/{community_name}/envelopes/downloads' do
      operation :post do
        key :operationId, 'postApiEnvelopesDownloads'
        key :description, "Starts new download"
        key :produces, ['application/json']

        parameter community_name

        response 201 do
          key :description, 'Download object'
          schema { key :'$ref', :EnvelopeDownload }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/downloads/{id}' do
      operation :get do
        key :operationId, 'getApiEnvelopesDownloads'
        key :description, "Returns download's status and URL"
        key :produces, ['application/json']

        parameter community_name
        parameter name: :id,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Download ID'

        response 200 do
          key :description, 'Download object'
          schema { key :'$ref', :EnvelopeDownload }
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
        parameter envelope_id
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
                 '/revisions/{revision_id}' do
      operation :get do
        key :operationId, 'getApiEnvelopeVersion'
        key :description, 'Retrieves a specific envelope revision'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id
        parameter include_deleted
        parameter name: :revision_id,
                  in: :path,
                  type: :string,
                  required: true,
                  description: 'Unique revision identifier'

        response 200 do
          key :description, 'Retrieves a specific envelope revision'
          schema { key :'$ref', :Envelope }
        end
      end
    end

    swagger_path '/{community_name}/envelopes/{envelope_id}/verify' do
      operation :patch do
        key :operationId, 'patchApiVerifyEnvelope'
        key :description, 'Updates verification date'
        key :produces, ['application/json']

        parameter community_name
        parameter envelope_id

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'JSON object containing last_verified_on'
          key :required, true

          schema do
            key :type, :object
            property :last_verified_on do
              key :type, :string
              key :format, :date
              key :description, 'Last verification date'
              key :example, '2023-07-20'
            end
          end
        end

        response 200 do
          key :description, 'Retrieves a specific envelope revision'
          schema { key :'$ref', :Envelope }
        end
      end
    end

    swagger_path '/{community_name}/graph/{resource_id}' do
      operation :get do
        key :operationId, 'getApiCommunityResourceGraph'
        key :description, 'Retrieves a resource by identifier. If the resource' \
                          'is part of a graph, the entire graph is returned.'
        key :produces, ['application/json']

        parameter community_name
        parameter resource_id

        response 200 do
          key :description, 'Retrieves a resource by identifier'
        end
      end
    end

    swagger_path '/{community_name}/resources' do
      operation :post do
        key :operationId, 'postApiSingleResourceWithCommunity'
        key :description, 'Publishes a new resource'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter name: :update_if_exists,
                  in: :query,
                  type: :boolean,
                  required: false,
                  description: 'Whether to update the resource if exists'
        parameter request_envelope

        response 200 do
          key :description, 'Resource updated'
          schema { key :'$ref', :Envelope }
        end
        response 201 do
          key :description, 'Resource created'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end
    end

    swagger_path '/{community_name}/resources/{resource_id}' do
      operation :get do
        key :operationId, 'getApiSingleResourceWithCommunity'
        key :description, 'Retrieves a resource by identifier'
        key :produces, ['application/json']

        parameter community_name
        parameter resource_id

        response 200 do
          key :description, 'Retrieves a resource by identifier'
        end
      end

      operation :put do
        key :operationId, 'putApiSingleResourceWithCommunity'
        key :description, 'Updates a single resource'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter resource_id
        parameter request_envelope

        response 200 do
          key :description, 'Resource updated'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end

      operation :delete do
        key :operationId, 'deleteApiSingleResourceWithCommunity'
        key :description, 'Marks an existing resource as deleted'
        key :produces, ['application/json']
        key :consumes, ['application/json']

        parameter community_name
        parameter resource_id
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

    swagger_path '/metadata/organizations' do
      operation :get do
        key :operationId, 'getApiOrganizations'
        key :description, 'Get the list of publishing organizations available'
        key :produces, ['application/json']

        response 200 do
          key :description, 'List of publishing organizations'
          schema do
            key :type, :array
            items { key :'$ref', :Organization }
          end
        end
      end

      operation :post do
        key :operationId, 'postApiOrganizations'
        key :description, 'Create a new publishing organization'
        key :produces, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'JSON object containing name'
          key :required, true

          schema do
            key :required, [:name]

            property :name do
              key :type, :string
              key :description, "The organization's name"
            end
          end
        end

        response 201 do
          key :description, 'Organization created'
          schema { key :'$ref', :Organization }
        end
      end
    end

    swagger_path '/metadata/organizations/{organization_id}' do
      operation :get do
        key :operationId, 'getApiOrganization'
        key :description, 'Get an existing publishing organization'
        key :produces, ['application/json']

        parameter organization_id(description: 'The CTID of the organization')

        response 200 do
          key :description, 'The organization with the given CTID'
          schema { key :'$ref', :Organization }
        end

        response 404 do
          key :description, 'No organizations match the given ID'
        end
      end

      operation :delete do
        key :operationId, 'deleteApiOrganizations'
        key :description, 'Delete an existing publishing organization'
        key :produces, ['application/json']

        parameter organization_id(description: 'The CTID of the organization')

        response 204 do
          key :description, 'The organization has been deleted successfully'
        end

        response 404 do
          key :description, 'No organizations match the given ID'
        end

        response 403 do
          key :description, "The user isn't authorized to perform this action"
        end

        response 422 do
          key :description, 'The organization has published resources'
        end
      end
    end

    swagger_path '/metadata/organizations/{organization_id}/envelopes' do
      operation :get do
        key :operationId, 'getApiOrganizationEnvelopes'
        key :description, 'Get the list of envelopes owned by an organization'
        key :produces, ['application/json']

        parameter organization_id(description: 'The CTID of the organization')
        parameter metadata_only
        parameter page_param
        parameter per_page_param

        response 200 do
          key :description, 'List of envelopes'
          schema do
            key :type, :array
            items { key :'$ref', :Envelope }
          end
        end
      end
    end

    swagger_path '/metadata/publishers' do
      operation :get do
        key :operationId, 'getApiPublishers'
        key :description, 'Get the list of publishers available'
        key :produces, ['application/json']

        response 200 do
          key :description, 'List of publishers'
          schema do
            key :type, :array
            items { key :'$ref', :Publisher }
          end
        end
      end

      operation :post do
        key :operationId, 'postApiPublishers'
        key :description, 'Create a new publisher (only admin users can perform this action)'
        key :produces, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'Request body'
          key :required, true

          schema do
            key :required, [:name]

            property :name do
              key :type, :string
              key :description, 'Name of the entity'
            end

            property :contact_info do
              key :type, :string
              key :description, 'Contact information'
            end

            property :description do
              key :type, :string
              key :description, 'Description of the entity'
            end
          end
        end

        response 201 do
          key :description, 'Publisher created'
          schema { key :'$ref', :Publisher }
        end
      end
    end

    swagger_path '/resources/organizations/{organization_id}/documents' do
      operation :post do
        key :operationId, 'postApiPublish'
        key :description, 'Publish a resource on behalf of a given publishing organization. '\
                          'The resource is passed as a POST body, '\
                          'raw and without wrappers / envelopes of any kind.'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter organization_id(
          description: 'The CTID of the organization on whose behalf the user is publishing'
        )
        parameter published_by

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'Resource'
          key :required, true
          schema do
            key :type, :object
            key :additionalProperties, true
          end
        end

        response 201 do
          key :description, 'Resource created'
          schema { key :'$ref', :Envelope }
        end
        response 422 do
          key :description, 'Validation Error'
          schema { key :'$ref', :ValidationError }
        end
      end
    end

    swagger_path '/resources/documents/{ctid}' do
      operation :delete do
        key :operationId, 'deleteApiSingleEnvelopeOnBehalf'
        key :description, 'Marks a document as deleted on behalf of a given publishing organization.'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter ctid
        parameter purge

        response 204 do
          key :description, 'Deletes a document (either virtually or physically)'
        end

        response 404 do
          key :description, 'No documents match respective IDs'
        end
      end
    end

    swagger_path '/{community_name}/resources/documents/{ctid}' do
      operation :delete do
        key :operationId, 'deleteApiSingleEnvelopeOnBehalfWithCommunity'
        key :description, 'Marks a document as deleted on behalf of a given publishing organization.'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter community_name
        parameter ctid
        parameter purge

        response 204 do
          key :description, 'Deletes a document (either virtually or physically)'
        end

        response 404 do
          key :description, 'No documents match respective IDs'
        end
      end
    end

    swagger_path '/resources/documents/{ctid}/transfer' do
      operation :patch do
        key :operationId, 'patchApiTransferOwnership'
        key :description, 'Transfers ownership of a document to another publishing organization.'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter ctid
        parameter new_organization_id

        response 200 do
          key :description, 'Transfers ownership of a document'
          schema { key :'$ref', :Envelope }
        end

        response 404 do
          key :description, 'No organizations or documents match respective IDs'
        end
      end
    end

    swagger_path '/{community_name}/resources/documents/{ctid}/transfer' do
      operation :patch do
        key :operationId, 'patchApiTransferOwnership'
        key :description, 'Transfers ownership of a document to another publishing organization.'
        key :consumes, ['application/json']
        key :produces, ['application/json']

        parameter community_name
        parameter ctid
        parameter new_organization_id

        response 200 do
          key :description, 'Transfers ownership of a document'
          schema { key :'$ref', :Envelope }
        end

        response 404 do
          key :description, 'No organizations or documents match respective IDs'
        end
      end
    end

    swagger_path '/description_sets/{ctid}' do
      operation :get do
        key :operationId, 'getDescriptionSets'
        key :description, "Returns the given resource's description sets"
        key :produces, ['application/json']

        parameter ctid(description: 'The CTID of the resource')
        parameter name: :limit,
                  in: :query,
                  type: :integer,
                  required: false,
                  description: 'The number of URIs to be returned'
        parameter name: :path_contains,
                  in: :query,
                  type: :string,
                  required: false,
                  description: 'The string which the returned paths should partially match'
        parameter name: :path_exact,
                  in: :query,
                  type: :string,
                  required: false,
                  description: 'The string which the returned paths should fully match'

        response 200 do
          key :description, 'Array of descriptions sets'

          schema do
            key :type, :array
            items do
              key :$ref, :DescriptionSet
            end
          end
        end
      end
    end

    swagger_path '/description_sets' do
      operation :post do
        key :operationId, 'postDescriptionSets'
        key :description, "Returns the description sets for the given CTIDs"
        key :produces, ['application/json']

        parameter do
          key :name, :body
          key :in, :body
          key :description, 'Request body'
          key :required, true
          schema do
            key :'$ref', :RetrieveDescriptionSets
          end
        end

        response 200 do
          key :description, 'Array of descriptions sets and (optionally) resources'
          schema { key :'$ref', :DescriptionSetData }
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
      key :description, 'Retrieves a specific envelope revision'

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
      property :owned_by,
               type: 'string',
               description: 'CTID of the owner'
      property :published_by,
               type: 'string',
               description: 'CTID of the publisher'
      property :changed,
               type: 'boolean',
               description: 'Whether the envelope has changed'
      property :last_verified_on,
               type: 'string',
               description: 'Last verification date'
    end

    swagger_schema :NodeHeaders do
      property :resource_digest,
               type: :string
      property :revision_history,
               type: :array,
               items: { '$ref': '#/definitions/Revision' },
               description: 'Revisions of the envelope'
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

    swagger_schema :Revision do
      property :head,
               type: :boolean,
               description: 'Tells if it\'s the current revision'
      property :event,
               type: :string,
               description: 'What change caused the new revision'
      property :created_at,
               type: :string,
               format: :'date-time',
               description: 'When the revision was created'
      property :actor,
               type: :string,
               description: 'Who performed the changes'
      property :url,
               type: :string,
               description: 'Revision URL'
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

    swagger_schema :DeleteEnvelopeToken do
      key :description, 'Marks an envelope as deleted'

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
      property :envelope_id,
               type: :string,
               description: 'the ID of the envelope to be deleted'

      key :required, %i[
        delete_token
        delete_token_format
        delete_token_encoding
        delete_token_public_key-
        envelope_id
      ]
    end

    swagger_schema :DeleteToken do
      key :description, 'Marks a resource as deleted'

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

      key :required, %i[
        delete_token
        delete_token_format
        delete_token_encoding
        delete_token_public_key
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

      key :required, %i[
        envelope_type
        envelope_version
        resource
        resource_format
        resource_public_key
      ]
    end

    swagger_schema :Ctid do
      property :ctid,
               type: :string,
               description: 'Properly formated ctid "urn:ctid:{uuid}"'
    end

    swagger_schema :Organization do
      property :id,
               type: :string,
               description: 'Organization ID'
      property :_ctid,
               type: :string,
               description: 'Organization CTID'
      property :name,
               type: :string,
               description: 'Organization name'
      property :description,
               type: :string,
               description: 'Organization description'
    end

    swagger_schema :Publisher do
      property :id,
               type: :integer,
               description: 'Publisher id'
      property :name,
               type: :string,
               description: 'Publisher name'
      property :description,
               type: :string,
               description: 'Publisher description'
      property :contact_info,
               type: :string,
               description: 'Publisher contact info'
    end

    swagger_schema :Resource do
      property :@id,
               type: :string,
               description: 'Resource ID'

      property :@type,
               type: :string,
               description: 'Resource type'

      property 'ceterms:ctid',
               type: :string,
               description: 'Resource CTID'
    end

    swagger_schema :DescriptionSet do
      property :path,
               type: :string,
               description: 'Description set path'

      property :total,
               type: :integer,
               description: "Total number of URIs"

      property :uris,
               type: :array,
               items: { type: :string, description: "Resource URI" }
    end

    swagger_schema :DescriptionSetData do
      property :description_sets,
               type: :array,
               description: 'Description sets',
               items: { '$ref': '#/definitions/DescriptionSet' }

      property :resources,
               type: :array,
               description: 'Associated resources',
               items: { '$ref': '#/definitions/Resource' }
    end

    swagger_schema :Graph do
      property :'@id',
               type: :string,
               description: 'Graph ID'

      property :'@graph',
               type: :array,
               description: 'Graph resources',
               items: { '$ref': '#/definitions/Resource' }
    end

    swagger_schema :EnvelopeDownload do
      property :id,
               type: :string,
               description: 'ID'

      property :status,
               type: :string,
               description: 'Status (pending, in progress, finished, or failed)'

      property :url,
               type: :string,
               description: 'S3 URL (when finished)'
    end

    swagger_schema :RetrieveDescriptionSets do
      property :ctids do
        key :type, :array
        key :description, 'Array of CTIDs'

        items do
          key :type, :string
        end
      end

      property :include_graph_data do
        key :type, :boolean
        key :description, 'Whether to include other resources from the graph'
        key :default, false
      end

      property :include_resources do
        key :type, :boolean
        key :description, 'Whether to include resources alongside description sets'
        key :default, false
      end

      property :include_results_metadata do
        key :type, :boolean
        key :description, "Whether to include results' metadata alongside description sets and resources"
        key :default, false
      end

      property :per_branch_limit do
        key :type, :integer
        key :format, :int32
        key :description, 'The number of URIs to be returned'
      end

      property :path_contains do
        key :type, :string
        key :description, 'The string which the returned paths should partially match'
      end

      property :path_exact do
        key :type, :string
        key :description, 'The string which the returned paths should fully match'
      end
    end

    # ==========================================
    # Root Info

    swagger_root do
      key :swagger, '2.0'
      info do
        key :title, 'CE/Registry API'
        key :description, 'Documentation for the new API endpoints. '\
                          'You can check more detailed info on: '\
                          'https://github.com/CredentialEngine/CredentialRegistry/blob/master/README.md#docs'
        key :version, 'v1'

        contact name: 'CE/Registry',
                email: 'learningreg-dev@googlegroups.com',
                url: 'https://github.com/CredentialEngine/CredentialRegistry'

        license name: 'Apache License, Version 2.0',
                url: 'http://www.apache.org/licenses/LICENSE-2.0'
      end
      key :consumes, ['application/json']
      key :produces, ['application/json']

      security_definition :Bearer do
        key :type, :apiKey
        key :name, 'Authorization'
        key :in, :header
        key :description, 'Bearer token authentication'
      end
    end
  end
end
