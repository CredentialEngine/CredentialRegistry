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
              key :description, "Appends one or more URIs to the container's ceterms:hasMember"
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Containers']

              security

              parameter community_name
              parameter name: :container_ctid,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'CTID of the container'

              parameter do
                key :name, :uris
                key :in, :body
                key :description, "URI(s) to append to the container's ceterms:hasMember. " \
                                  'Can be a single URI or an array of URIs. ' \
                                  'Duplicates are ignored.'
                key :required, true

                schema do
                  key :type, :array
                  key :description, 'An array of resource URIs'
                  items do
                    key :type, :string
                    key :format, :uri
                    key :example, 'http://credentialengineregistry.org/resources/ce-abc123'
                  end
                end
              end

              response 200 do
                key :description, 'Successfully added theURI(s) to the container'
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

            operation :delete do # rubocop:todo Metrics/BlockLength
              key :operationId, 'deleteApiContainerResources'
              key :description, "Removes one or more URIs from the container's ceterms:hasMember"
              key :consumes, ['application/json']
              key :produces, ['application/json']
              key :tags, ['Containers']

              security

              parameter community_name
              parameter name: :container_ctid,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'CTID of the container'

              parameter do
                key :name, :uris
                key :in, :body
                key :description, "URI(s) to remove from the container's ceterms:hasMember. " \
                                  'Can be a single URI or an array of URIs.'
                key :required, true

                schema do
                  key :type, :array
                  key :description, 'An array of resource URIs'
                  items do
                    key :type, :string
                    key :format, :uri
                    key :example, 'http://credentialengineregistry.org/resources/ce-abc123'
                  end
                end
              end

              response 200 do
                key :description, 'Successfully removed the URI(s) from the container'
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
