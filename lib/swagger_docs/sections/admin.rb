module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module Admin # rubocop:todo Metrics/ModuleLength, Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/metadata/envelope_communities' do
            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiEnvelopeCommunities'
              key :description, 'Creates an envelope community'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter do # rubocop:todo Metrics/BlockLength
                key :name, :body
                key :in, :body
                key :description, 'JSON object containing the envelope community params'
                key :required, true

                schema do
                  key :required, [:name]

                  property :name do
                    key :type, :string
                    key :description, "The envelope community's name"
                  end

                  property :default do
                    key :type, :boolean
                    key :default, false
                    key :description, 'Whether the envelope community is default'
                  end

                  property :secured do
                    key :type, :boolean
                    key :default, false
                    key :description, 'Whether the envelope community is secured'
                  end

                  property :secured_search do
                    key :type, :boolean
                    key :default, false
                    key :description, "Whether the envelope community's search is secured"
                  end
                end
              end

              response 200 do
                key :description, 'An envelope community'

                schema do
                  key :type, :object
                  property :name do
                    key :type, :string
                    key :description, "The envelope community's name"
                  end
                end
              end
            end
          end
          swagger_path '/metadata/json_contexts' do
            operation :get do
              key :operationId, 'getApiJsonContexts'
              key :description, 'Retrieves all JSON contexts'
              key :produces, ['application/json']
              key :tags, ['Admin']

              response 200 do
                key :description, 'JSON context updated'
                schema do
                  key :type, :array
                  items { key :$ref, :JsonContext }
                end
              end
            end

            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiJsonContexts'
              key :description, 'Uploads a JSON context'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'Request body'
                key :required, true

                schema do
                  key :required, %i[context url]

                  property :context do
                    key :type, :object
                    key :description, 'Context payload'
                  end

                  property :url do
                    key :type, :string
                    key :description, 'Context URL'
                  end
                end
              end

              response 200 do
                key :description, 'JSON context updated'
                schema { key :$ref, :JsonContext }
              end

              response 201 do
                key :description, 'JSON context created'
                schema { key :$ref, :JsonContext }
              end
            end
          end

          swagger_path '/metadata/json_contexts/{url}' do
            operation :get do
              key :operationId, 'getApiJsonContext'
              key :description, 'Retrieves a JSON context by its URL'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter name: :url,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'The URL of the JSON context'

              response 200 do
                key :description, 'JSON context updated'
                schema { key :$ref, :JsonContext }
              end
            end
          end

          swagger_path '/metadata/organizations' do
            operation :get do
              key :operationId, 'getApiOrganizations'
              key :description, 'Get the list of publishing organizations available'
              key :produces, ['application/json']
              key :tags, ['Admin']

              response 200 do
                key :description, 'List of publishing organizations'
                schema do
                  key :type, :array
                  items { key :$ref, :Organization }
                end
              end
            end

            operation :post do
              key :operationId, 'postApiOrganizations'
              key :description, 'Create a new publishing organization'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'JSON object containing name'
                key :required, true

                schema do
                  key :required, [:name]

                  property :name do
                    key :type, :string
                    key :description, "The organization's name"
                  end
                end
              end

              response 201 do
                key :description, 'Organization created'
                schema { key :$ref, :Organization }
              end
            end
          end

          swagger_path '/metadata/organizations/{organization_id}' do
            operation :get do
              key :operationId, 'getApiOrganization'
              key :description, 'Get an existing publishing organization'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter organization_id(description: 'The CTID of the organization')

              response 200 do
                key :description, 'The organization with the given CTID'
                schema { key :$ref, :Organization }
              end

              response 404 do
                key :description, 'No organizations match the given ID'
              end
            end

            operation :delete do
              key :operationId, 'deleteApiOrganizations'
              key :description, 'Delete an existing publishing organization'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter organization_id(description: 'The CTID of the organization')

              response 204 do
                key :description, 'The organization has been deleted successfully'
              end

              response 404 do
                key :description, 'No organizations match the given ID'
              end

              response 403 do
                key :description, "The user isn't authorized to perform this action"
              end

              response 422 do
                key :description, 'The organization has published resources'
              end
            end
          end

          swagger_path '/metadata/organizations/{organization_id}/envelopes' do
            operation :get do
              key :operationId, 'getApiOrganizationEnvelopes'
              key :description, 'Get the list of envelopes owned by an organization'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter organization_id(description: 'The CTID of the organization')
              parameter metadata_only
              parameter page_param
              parameter per_page_param

              response 200 do
                key :description, 'List of envelopes'
                schema do
                  key :type, :array
                  items { key :$ref, :Envelope }
                end
              end
            end
          end

          swagger_path '/metadata/publishers' do
            operation :get do
              key :operationId, 'getApiPublishers'
              key :description, 'Get the list of publishers available'
              key :produces, ['application/json']
              key :tags, ['Admin']

              response 200 do
                key :description, 'List of publishers'
                schema do
                  key :type, :array
                  items { key :$ref, :Publisher }
                end
              end
            end

            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiPublishers'
              key :description, 'Create a new publisher (only admin users can perform this action)'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'Request body'
                key :required, true

                schema do
                  key :required, [:name]

                  property :name do
                    key :type, :string
                    key :description, 'Name of the entity'
                  end

                  property :contact_info do
                    key :type, :string
                    key :description, 'Contact information'
                  end

                  property :description do
                    key :type, :string
                    key :description, 'Description of the entity'
                  end
                end
              end

              response 201 do
                key :description, 'Publisher created'
                schema { key :$ref, :Publisher }
              end
            end
          end

          swagger_path '/metadata/{community_name}/config' do
            operation :get do
              key :operationId, 'getApiConfig'
              key :description, "Get the envelope community's config"
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter community_name

              response 200 do
                key :description, "The envelope community's config"
                key :type, :object
              end
            end

            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiConfig'
              key :description, 'Uploads a config for the envelope community'
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter community_name

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'JSON object containing a config and its description'
                key :required, true

                schema do
                  key :required, %i[description payload]

                  property :description do
                    key :type, :string
                    key :description, 'Config description'
                  end

                  property :payload do
                    key :type, :object
                    key :description, 'Config payload'
                  end
                end
              end

              response 201 do
                key :description, 'Config uploaded'
                key :type, :object
              end
            end
          end

          swagger_path '/metadata/{community_name}/config/changes' do
            operation :get do
              key :operationId, 'getApiConfigChanges'
              key :description, "Get the changes to the envelope community's config"
              key :produces, ['application/json']
              key :tags, ['Admin']

              parameter community_name

              response 200 do
                key :description, "The changes to the envelope community's config"

                schema do
                  key :type, :array
                  items { key :$ref, :EnvelopeCommunityConfigChange }
                end
              end
            end
          end
        end
      end
    end
  end
end
