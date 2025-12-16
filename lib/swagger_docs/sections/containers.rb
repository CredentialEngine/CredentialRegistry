module MetadataRegistry
  class SwaggerDocs
    module Sections
      # Swagger documentation for Containers API
      module Containers
        extend ActiveSupport::Concern

        included do
          swagger_path '/{community_name}/containers/{container_ctid}/resources' do
            operation :patch do # rubocop:todo Metrics/BlockLength
              key :operationId, 'patchApiContainerResources'
              key :description, 'Adds a resource to a container collection'
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Containers']

              security

              parameter community_name
              parameter name: :container_ctid,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'CTID of the container collection'

              parameter do
                key :name, :subresource
                key :in, :body
                key :description, 'JSON-LD subresource to add to the container'
                key :required, true

                schema do
                  key :type, :object
                  key :description, 'A JSON-LD resource object'
                  property :@id do
                    key :type, :string
                    key :description, 'Resource identifier'
                    key :example, 'http://credentialengineregistry.org/resources/ce-abc123'
                  end
                  property :@type do
                    key :type, :string
                    key :description, 'Resource type'
                    key :example, 'ceterms:Credential'
                  end
                  property :'ceterms:ctid' do
                    key :type, :string
                    key :description, 'CTID of the resource'
                    key :example, 'ce-abc123'
                  end
                end
              end

              response 200 do
                key :description, 'Successfully added resource to container'
                schema { key :$ref, :Envelope }
              end

              response 401 do
                key :description, 'Unauthorized - authentication required'
              end

              response 403 do
                key :description, 'Forbidden - insufficient permissions'
              end

              response 404 do
                key :description, 'Container not found or not a collection type'
              end
            end
          end

          swagger_path '/{community_name}/containers/{container_ctid}/resources/{resource_ctid}' do
            operation :delete do # rubocop:todo Metrics/BlockLength
              key :operationId, 'deleteApiContainerResource'
              key :description, 'Removes a resource from a container collection'
              key :produces, ['application/json']
              key :tags, ['Containers']

              security

              parameter community_name
              parameter name: :container_ctid,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'CTID of the container collection'
              parameter name: :resource_ctid,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'CTID of the resource to remove'

              response 200 do
                key :description, 'Successfully removed resource from container'
                schema { key :$ref, :Envelope }
              end

              response 401 do
                key :description, 'Unauthorized - authentication required'
              end

              response 403 do
                key :description, 'Forbidden - insufficient permissions'
              end

              response 404 do
                key :description, 'Container not found or not a collection type'
              end
            end
          end
        end
      end
    end
  end
end
