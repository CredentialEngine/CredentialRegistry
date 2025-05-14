module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module IndexedResources # rubocop:todo Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/indexed_resources/schema' do
            operation :get do
              key :operationId, 'postApiIndexedResourcesSchema'
              key :description, 'Retrieve the indexed resources schema'
              key :produces, ['application/json']
              key :tags, ['Indexed resources']

              response 200 do
                key :description, 'Indexed resources schema'
                key :type, :object
              end
            end
          end

          swagger_path '/indexed_resources/{ctid}' do
            operation :get do
              key :operationId, 'getApiIndexedResource'
              key :description, 'Retrieve an indexed resource by its CTID'
              key :produces, ['application/json']
              key :tags, ['Indexed resources']

              parameter ctid(description: 'The CTID of the indexed resource')

              response 200 do
                key :description, 'Indexed resource'
                key :type, :object
              end
            end
          end

          swagger_path '/{community_name}/indexed_resources/{ctid}' do
            operation :get do
              key :operationId, 'getApiIndexedResourceByCommunity'
              key :description, 'Retrieve an indexed resource by its CTID'
              key :produces, ['application/json']
              key :tags, ['Indexed resources']

              parameter community_name
              parameter ctid(description: 'The CTID of the indexed resource')

              response 200 do
                key :description, 'Indexed resource'
                key :type, :object
              end
            end
          end
        end
      end
    end
  end
end
