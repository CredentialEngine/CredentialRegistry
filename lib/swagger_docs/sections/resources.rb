module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module Resources # rubocop:todo Metrics/ModuleLength, Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/resources' do
            operation :post do
              key :operationId, 'postApiSingleResource'
              key :description, 'Publishes a new resource'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

              parameter name: :update_if_exists,
                        in: :query,
                        type: :boolean,
                        required: false,
                        description: 'Whether to update the resource if exists'
              parameter request_envelope

              response 200 do
                key :description, 'Resource updated'
                schema { key :$ref, :Envelope }
              end
              response 201 do
                key :description, 'Resource created'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/resources/organizations/{organization_id}/documents' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiPublish'
              # rubocop:todo Layout/LineLength
              key :description, 'Publish a resource on behalf of a given publishing organization. ' \
                                'The resource is passed as a POST body, ' \
                                'raw and without wrappers / envelopes of any kind.'
              # rubocop:enable Layout/LineLength
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Resources']

              parameter organization_id(
                description: 'The CTID of the organization on whose behalf the user is publishing'
              )
              parameter published_by
              parameter name: 'skip_validation',
                        in: :query,
                        type: :boolean,
                        description: 'Whether to skip validation against the JSON schema'

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
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/resources/{resource_id}' do
            operation :get do
              key :operationId, 'getApiSingleResource'
              key :description, 'Retrieves a resource by identifier'
              key :produces, ['application/json']
              key :tags, ['Resources']

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
              key :tags, ['Resources']

              parameter resource_id
              parameter request_envelope

              response 200 do
                key :description, 'Resource updated'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end

            operation :delete do
              key :operationId, 'deleteApiSingleResource'
              key :description, 'Marks an existing resource as deleted'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

              parameter resource_id
              parameter delete_token

              response 204 do
                key :description, 'Marks an existing envelope as deleted'
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/{community_name}/resources' do
            operation :post do
              key :operationId, 'postApiSingleResourceWithCommunity'
              key :description, 'Publishes a new resource'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

              parameter community_name
              parameter name: :update_if_exists,
                        in: :query,
                        type: :boolean,
                        required: false,
                        description: 'Whether to update the resource if exists'
              parameter request_envelope

              response 200 do
                key :description, 'Resource updated'
                schema { key :$ref, :Envelope }
              end
              response 201 do
                key :description, 'Resource created'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/{community_name}/resources/{resource_id}' do
            operation :get do
              key :operationId, 'getApiSingleResourceWithCommunity'
              key :description, 'Retrieves a resource by identifier'
              key :produces, ['application/json']
              key :tags, ['Resources']

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
              key :tags, ['Resources']

              parameter community_name
              parameter resource_id
              parameter request_envelope

              response 200 do
                key :description, 'Resource updated'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end

            operation :delete do
              key :operationId, 'deleteApiSingleResourceWithCommunity'
              key :description, 'Marks an existing resource as deleted'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

              parameter community_name
              parameter resource_id
              parameter delete_token

              response 204 do
                key :description, 'Marks an existing envelope as deleted'
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/resources/check_existence' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiResourceCheckExistence'
              key :description, 'Returns existing CTIDs'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

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
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiResourceSearch'
              key :description, 'Returns resources with the given CTIDs or bnode IDs'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Resources']

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

          swagger_path '/resources/documents/{ctid}' do
            operation :delete do
              key :operationId, 'deleteApiSingleEnvelopeOnBehalf'
              key :description,
                  'Deletes a document on behalf of a given publishing organization.'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Resources']

              parameter ctid

              response 204 do
                key :description, 'Deletes a document'
              end

              response 404 do
                key :description, 'No documents match respective IDs'
              end
            end
          end

          swagger_path '/{community_name}/resources/documents/{ctid}' do
            operation :delete do
              key :operationId, 'deleteApiSingleEnvelopeOnBehalfWithCommunity'
              key :description,
                  'Deletes a document on behalf of a given publishing organization.'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Resources']

              parameter community_name
              parameter ctid

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
              key :description,
                  'Transfers ownership of a document to another publishing organization.'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Resources']

              parameter ctid
              parameter new_organization_id

              response 200 do
                key :description, 'Transfers ownership of a document'
                schema { key :$ref, :Envelope }
              end

              response 404 do
                key :description, 'No organizations or documents match respective IDs'
              end
            end
          end

          swagger_path '/{community_name}/resources/documents/{ctid}/transfer' do
            operation :patch do
              key :operationId, 'patchApiTransferOwnership'
              key :description,
                  'Transfers ownership of a document to another publishing organization.'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Resources']

              parameter community_name
              parameter ctid
              parameter new_organization_id

              response 200 do
                key :description, 'Transfers ownership of a document'
                schema { key :$ref, :Envelope }
              end

              response 404 do
                key :description, 'No organizations or documents match respective IDs'
              end
            end
          end
        end
      end
    end
  end
end
