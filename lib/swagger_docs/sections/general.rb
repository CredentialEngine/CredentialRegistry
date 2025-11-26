module MetadataRegistry
  class SwaggerDocs
    module Sections
      module General # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/' do
            operation :get do
              key :operationId, 'getApi'
              key :description, 'API root'
              key :produces, ['application/json']
              key :tags, ['General']

              # security

              response 200 do
                key :description, 'API root'
                schema { key :$ref, :ApiRoot }
              end
            end
          end

          swagger_path '/info' do
            operation :get do
              key :operationId, 'getApiInfo'
              key :description, 'General info about this API node'
              key :produces, ['application/json']
              key :tags, ['General']

              # security

              response 200 do
                key :description, 'General info about this API node'
                schema { key :$ref, :ApiInfo }
              end
            end
          end

          swagger_path '/readme' do
            operation :get do
              key :operationId, 'getReadme'
              key :description, 'Show the README rendered in HTML'
              key :produces, ['text/html']
              key :tags, ['General']

              # security

              response 200, description: 'shows the README rendered in HTML'
            end
          end

          swagger_path '/ce-registry/ctid' do
            operation :get do
              key :operationId, 'getApiCtid'
              key :description, 'Retrieve a new ctid'
              key :produces, ['application/json']
              key :tags, ['General']

              # security

              response 200 do
                key :description, 'Retrieve a new ctid'
                schema { key :$ref, :Ctid }
              end
            end
          end
        end
      end
    end
  end
end
