module MetadataRegistry
  class SwaggerDocs
    module Sections
      module Graphs # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/graph/{resource_id}' do
            operation :get do
              key :operationId, 'getApiResourceGraph'
              key :description, 'Retrieves a resource by identifier. If the resource' \
                                'is part of a graph, the entire graph is returned.'
              key :produces, ['application/json']
              key :tags, ['Graphs']

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

          swagger_path '/{community_name}/graph/{resource_id}' do
            operation :get do
              key :operationId, 'getApiCommunityResourceGraph'
              key :description, 'Retrieves a resource by identifier. If the resource' \
                                'is part of a graph, the entire graph is returned.'
              key :produces, ['application/json']
              key :tags, ['Graphs']

              parameter community_name
              parameter resource_id

              response 200 do
                key :description, 'Retrieves a resource by identifier'
              end
            end
          end

          swagger_path '/graph/search' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiGraphSearch'
              key :description, 'Retrieves graphs by the given CTIDs'
              key :produces, ['application/json']
              key :tags, ['Graphs']

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
        end
      end
    end
  end
end
