module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module Indexer # rubocop:todo Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/indexed_resources/schema' do
            operation :get do
              key :operationId, 'postApiIndexedResourcesSchema'
              key :description, 'Retrieve the indexed resources schema'
              key :produces, ['application/json']
              key :tags, ['Indexer']

              response 200 do
                key :description, 'Indexed resources schema'
                key :type, :object
              end
            end
          end

          swagger_path '/{community_name}/indexed_resources/{ctid}' do
            operation :get do
              key :operationId, 'getApiIndexedResourceByCommunity'
              key :description, 'Retrieve an indexed resource by its CTID'
              key :produces, ['application/json']
              key :tags, ['Indexer']

              parameter community_name
              parameter ctid(description: 'The CTID of the indexed resource')

              response 200 do
                key :description, 'Indexed resource'
                key :type, :object
              end
            end
          end

          swagger_path '/{community_name}/indexer/stats' do
            operation :get do
              key :operationId, 'getApiIndexerStatsByCommunity'
              key :description, 'Shows how many indexing jobs are in the queue'
              key :produces, ['application/json']
              key :tags, ['Indexer']

              parameter community_name

              response 200 do
                key :description, 'Indexer stats'
                schema do
                  property :enqueued_jobs,
                           type: :number,
                           description: 'Number of indexing jobs waiting in the queue'
                  property :in_progress_jobs,
                           type: :number,
                           description: 'Number of indexing jobs in progress'
                end
              end
            end
          end
        end
      end
    end
  end
end
