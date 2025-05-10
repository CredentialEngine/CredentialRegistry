module MetadataRegistry
  class SwaggerDocs
    module Sections
      module DescriptionSets # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/description_sets' do
            operation :post do
              key :operationId, 'postDescriptionSets'
              key :description, 'Returns the description sets for the given CTIDs'
              key :produces, ['application/json']
              key :tags, ['Description sets']

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'Request body'
                key :required, true
                schema do
                  key :$ref, :RetrieveDescriptionSets
                end
              end

              response 200 do
                key :description, 'Array of descriptions sets and (optionally) resources'
                schema { key :$ref, :DescriptionSetData }
              end
            end
          end

          swagger_path '/description_sets/{ctid}' do
            operation :get do # rubocop:todo Metrics/BlockLength
              key :operationId, 'getDescriptionSets'
              key :description, "Returns the given resource's description sets"
              key :produces, ['application/json']
              key :tags, ['Description sets']

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
        end
      end
    end
  end
end
