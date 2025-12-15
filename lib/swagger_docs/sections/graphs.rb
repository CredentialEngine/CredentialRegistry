module MetadataRegistry
  class SwaggerDocs
    module Sections
      module Graphs # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/{community_name}/graph/download' do
            operation :get do
              key :operationId, 'getApiGraphDownload'
              key :description, "Returns the download's status and URL"
              key :produces, ['application/json']
              key :tags, ['Graphs']

              parameter community_name

              response 200 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end

            operation :post do
              key :operationId, 'postApiGraphDownloads'
              key :description, 'Starts a new download'
              key :produces, ['application/json']
              key :tags, ['Graphs']

              parameter community_name

              response 201 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end
          end

          swagger_path '/{community_name}/graph/search' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiGraphSearch'
              key :description, 'Retrieves graphs by the given CTIDs'
              key :produces, ['application/json']
              key :tags, ['Graphs']

              security

              parameter community_name

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

          swagger_path '/{community_name}/graph/{resource_id}' do
            operation :get do
              key :operationId, 'getApiGraphResource'
              key :description, 'Retrieves a resource by identifier. If the resource' \
                                'is part of a graph, the entire graph is returned.'
              key :produces, ['application/json']
              key :tags, ['Graphs']

              security

              parameter community_name
              parameter resource_id

              response 200 do
                key :description, 'Retrieves a resource by identifier'
              end
            end
          end
        end
      end
    end
  end
end
