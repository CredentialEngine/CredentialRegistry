module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module Search # rubocop:todo Metrics/ModuleLength, Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/ctdl' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postCtdl'
              key :description, 'Query resources using the CTDL language'
              key :produces, ['application/json']
              key :tags, ['Search']

              parameter name: :include_description_sets,
                        type: :boolean,
                        default: false,
                        in: :query,
                        description: 'Whether to include description sets'

              parameter name: :include_description_set_resources,
                        type: :boolean,
                        default: false,
                        in: :query,
                        description: 'Whether to include resources of descriptions sets'

              parameter name: :include_graph_data,
                        type: :boolean,
                        default: false,
                        in: :query,
                        description: 'Whether to include other resources from the graph'

              parameter name: :include_results_metadata,
                        type: :boolean,
                        default: false,
                        in: :query,
                        description: 'Whether to include results metadata (owner, publisher, etc)'

              parameter name: :order_by,
                        type: :string,
                        enum: CtdlQuery::SORT_OPTIONS.flat_map { [_1, "^#{_1}"] },
                        default: '^search:recordUpdated',
                        in: :query,
                        description: 'Order in which sort results'

              parameter name: :skip,
                        type: :integer,
                        default: 0,
                        in: :query,
                        description: 'How many first results to skip'

              parameter name: :take,
                        type: :integer,
                        default: 10,
                        in: :query,
                        description: 'How many first results to take'

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'CTDL query'
                key :required, true
                schema do
                  key :type, :object
                  key :additionalProperties, true
                end
              end

              response 200 do
                key :description, 'Search results'
                schema { key :$ref, :CtdlSearchResults }
              end
            end
          end

          swagger_path '/search' do
            operation :get do
              key :operationId, 'getApiSearch'
              key :description, 'Search envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
              key :produces, ['application/json']
              key :tags, ['Search']

              parameters_for_search

              response 200 do
                key :description, 'Search envelopes'
                schema do
                  key :type, :array
                  items { key :$ref, :Envelope }
                end
              end
            end
          end

          swagger_path '/{community_name}/search' do
            operation :get do
              key :operationId, 'getApiCommunitySearch'
              key :description, 'Search by community envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
              key :produces, ['application/json']
              key :tags, ['Search']

              parameter community_name
              parameters_for_search

              response 200 do
                key :description, 'Search by community envelopes'
                schema do
                  key :type, :array
                  items { key :$ref, :Envelope }
                end
              end
            end
          end

          swagger_path '/{community_name}/{resource_type}/search' do
            operation :get do
              key :operationId, 'getApiResourceTypeSearch'
              key :description, 'Search by resource_type envelopes. For more info: https://github.com/CredentialEngine/CredentialRegistry/blob/master/docs/07_search.md'
              key :produces, ['application/json']
              key :tags, ['Search']

              parameter community_name
              parameter resource_type(_in: :path)
              parameters_for_search

              response 200 do
                key :description, 'Search by resource_type envelopes'
                schema do
                  key :type, :array
                  items { key :$ref, :Envelope }
                end
              end
            end
          end
        end
      end
    end
  end
end
