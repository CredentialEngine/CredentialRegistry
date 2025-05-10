module MetadataRegistry
  class SwaggerDocs
    module Sections
      module Communities # rubocop:todo Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/{community_name}' do
            operation :get do
              key :operationId, 'getApiCommunity'
              key :description, 'Retrieve metadata community'
              key :produces, ['application/json']
              key :tags, ['Envelope communities']

              parameter community_name

              response 200 do
                key :description, 'Retrieve metadata community'
                schema { key :$ref, :Community }
              end
            end
          end

          swagger_path '/{community_name}/info' do
            operation :get do
              key :operationId, 'getApiCommunityInfo'
              key :description, 'General info about this metadata community'
              key :produces, ['application/json']
              key :tags, ['Envelope communities']

              parameter community_name

              response 200 do
                key :description, 'General info about this metadata community'
                schema { key :$ref, :CommunityInfo }
              end
            end
          end
        end
      end
    end
  end
end
