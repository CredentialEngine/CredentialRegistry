module MetadataRegistry
  class SwaggerDocs
    # rubocop:todo Style/Documentation
    module Models # rubocop:todo Metrics/ModuleLength, Style/Documentation
      # rubocop:enable Style/Documentation
      extend ActiveSupport::Concern

      included do
        swagger_schema :ApiRoot do
          property :api_version,
                   type: :string,
                   description: 'API version number'
          property :total_envelopes,
                   type: :integer,
                   format: :int32,
                   description: 'Total count of metadata envelopes'
          property :metadata_communities,
                   type: :object,
                   description: 'Object with community names and their API urls'
          property :info,
                   type: :string,
                   description: 'URL for the API info'
        end

        swagger_schema :ApiInfo do
          property :metadata_communities,
                   type: :object,
                   description: 'Object with community names and their API urls'
          property :postman,
                   type: :string,
                   description: 'URL for the postman collection'
          property :swagger,
                   type: :string,
                   description: 'URL for the Swagger docs'
          property :readme,
                   type: :string,
                   description: 'URL for the repo\'s README doc'
          property :docs,
                   type: :string,
                   description: 'URL for the docs folder'
        end

        swagger_schema :SchemasInfo do
          property :available_schemas,
                   type: :array,
                   description: 'List of json-schema URLs available',
                   items: { type: :string, description: 'json-schema URL' }
          property :specification,
                   type: :string,
                   description: 'URL for the json-schema spec'
        end

        swagger_schema :Community do
          property :id,
                   type: :integer,
                   format: :int32,
                   description: 'Community id'
          property :name,
                   type: :string,
                   description: 'Community name'
          property :backup_item,
                   type: :string,
                   description: 'Backup item name on Internet Archive'
          property :default,
                   type: :boolean,
                   description: 'Wether this is the default Community or not'
          property :created_at,
                   type: :string,
                   format: :'date-time',
                   description: 'When the version was created'
          property :updated_at,
                   type: :string,
                   format: :'date-time',
                   description: 'When the version was updated'
        end

        swagger_schema :CommunityInfo do
          property :total_envelopes,
                   type: :integer,
                   format: :int32,
                   description: 'Total count of envelopes for this community'
          property :backup_item,
                   type: :string,
                   description: 'Internet Archive backup item identifier'
        end

        swagger_schema :EnvelopesInfo do
          property :POST do
            key :description, 'Info for POST requests'
            property :accepted_schemas,
                     description: 'List of accepted_schemas',
                     type: :array,
                     items: { type: :string, description: 'json-schema URL' }
          end
          property :PUT do
            key :description, 'Info for PUT requests'
            property :accepted_schemas,
                     description: 'List of accepted_schemas',
                     type: :array,
                     items: { type: :string, description: 'json-schema URL' }
          end
        end

        swagger_schema :SingleEnvelopeInfo do
          property :PATCH do
            key :description, 'Info for PATCH requests'
            property :accepted_schemas,
                     description: 'List of accepted_schemas',
                     type: :array,
                     items: { type: :string, description: 'json-schema URL' }
          end
          property :DELETE do
            key :description, 'Info for DELETE requests'
            property :accepted_schemas,
                     description: 'List of accepted_schemas',
                     type: :array,
                     items: { type: :string, description: 'json-schema URL' }
          end
        end

        swagger_schema :Envelope do
          key :description, 'Retrieves a specific envelope revision'

          property :envelope_id,
                   type: :string,
                   description: 'Unique identifier (in UUID format)'
          property :envelope_type,
                   type: :string,
                   description: 'Type ("resource_data" or "paradata")'
          property :envelope_version,
                   type: :string,
                   description: 'Envelope version used'
          property :resource,
                   type: 'string',
                   description: 'Resource in its original encoded format'
          property :decoded_resource,
                   type: 'string',
                   description: 'Resource in decoded form'
          property :resource_format,
                   type: 'string',
                   description: 'Format of the submitted resource'
          property :resource_encoding,
                   type: 'string',
                   description: 'Encoding of the submitted resource'
          property :node_headers,
                   description: 'Additional headers added by the node',
                   '$ref': :NodeHeaders
          property :owned_by,
                   type: 'string',
                   description: 'CTID of the owner'
          property :published_by,
                   type: 'string',
                   description: 'CTID of the publisher'
          property :changed,
                   type: 'boolean',
                   description: 'Whether the envelope has changed'
          property :last_verified_on,
                   type: 'string',
                   description: 'Last verification date'
        end

        swagger_schema :NodeHeaders do
          property :resource_digest,
                   type: :string
          property :revision_history,
                   type: :array,
                   items: { '$ref': '#/definitions/Revision' },
                   description: 'Revisions of the envelope'
          property :created_at,
                   type: :string,
                   format: :'date-time',
                   description: 'Creation date'
          property :updated_at,
                   type: :string,
                   format: :'date-time',
                   description: 'Last modification date'
          property :deleted_at,
                   type: :string,
                   format: :'date-time',
                   description: 'Deletion date'
        end

        swagger_schema :Revision do
          property :head,
                   type: :boolean,
                   description: 'Tells if it\'s the current revision'
          property :event,
                   type: :string,
                   description: 'What change caused the new revision'
          property :created_at,
                   type: :string,
                   format: :'date-time',
                   description: 'When the revision was created'
          property :actor,
                   type: :string,
                   description: 'Who performed the changes'
          property :url,
                   type: :string,
                   description: 'Revision URL'
        end

        swagger_schema :ValidationError do
          property :errors,
                   description: 'List of validation error messages',
                   type: :array,
                   items: { type: :string }
          property :json_schema,
                   description: 'List of json-schema\'s used for validation',
                   type: :array,
                   items: { type: :string, description: 'json-schema URL' }
        end

        swagger_schema :DeleteEnvelopeToken do
          key :description, 'Marks an envelope as deleted'

          property :delete_token,
                   type: :string,
                   description: 'Any content signed with the user\'s private key'
          property :delete_token_format,
                   type: :string,
                   description: 'Format of the submitted delete token'
          property :delete_token_encoding,
                   type: :string,
                   description: 'Encoding of the submitted delete token'
          property :delete_token_public_key,
                   type: :string,
                   description: 'RSA key in PEM format (same pair used to encode)'
          property :envelope_id,
                   type: :string,
                   description: 'the ID of the envelope to be deleted'

          key :required, %i[
            delete_token
            delete_token_format
            delete_token_encoding
            delete_token_public_key-
            envelope_id
          ]
        end

        swagger_schema :DeleteToken do
          key :description, 'Marks a resource as deleted'

          property :delete_token,
                   type: :string,
                   description: 'Any content signed with the user\'s private key'
          property :delete_token_format,
                   type: :string,
                   description: 'Format of the submitted delete token'
          property :delete_token_encoding,
                   type: :string,
                   description: 'Encoding of the submitted delete token'
          property :delete_token_public_key,
                   type: :string,
                   description: 'RSA key in PEM format (same pair used to encode)'

          key :required, %i[
            delete_token
            delete_token_format
            delete_token_encoding
            delete_token_public_key
          ]
        end

        swagger_schema :RequestEnvelope do
          key :description, 'Publishes a new envelope'

          property :envelope_id,
                   type: :string,
                   description: 'Unique identifier (in UUID format)'
          property :envelope_type,
                   type: :string,
                   description: 'Type ("resource_data" or "paradata")'
          property :envelope_version,
                   type: :string,
                   description: 'Envelope version used'
          property :resource,
                   type: 'string',
                   description: 'Resource in its original encoded format'
          property :resource_format,
                   type: 'string',
                   description: 'Format of the submitted resource'
          property :resource_encoding,
                   type: 'string',
                   description: 'Encoding of the submitted resource'
          property :resource_public_key,
                   type: :string,
                   description: 'RSA key in PEM format (same pair used to encode)'

          key :required, %i[
            envelope_type
            envelope_version
            resource
            resource_format
            resource_public_key
          ]
        end

        swagger_schema :Ctid do
          property :ctid,
                   type: :string,
                   description: 'Properly formated ctid "urn:ctid:{uuid}"'
        end

        swagger_schema :Organization do
          property :id,
                   type: :string,
                   description: 'Organization ID'
          property :_ctid,
                   type: :string,
                   description: 'Organization CTID'
          property :name,
                   type: :string,
                   description: 'Organization name'
          property :description,
                   type: :string,
                   description: 'Organization description'
        end

        swagger_schema :Publisher do
          property :id,
                   type: :integer,
                   description: 'Publisher id'
          property :name,
                   type: :string,
                   description: 'Publisher name'
          property :description,
                   type: :string,
                   description: 'Publisher description'
          property :contact_info,
                   type: :string,
                   description: 'Publisher contact info'
        end

        swagger_schema :Resource do
          property :@id,
                   type: :string,
                   description: 'Resource ID'

          property :@type,
                   type: :string,
                   description: 'Resource type'

          property 'ceterms:ctid',
                   type: :string,
                   description: 'Resource CTID'
        end

        swagger_schema :DescriptionSet do
          property :path,
                   type: :string,
                   description: 'Description set path'

          property :total,
                   type: :integer,
                   description: 'Total number of URIs'

          property :uris,
                   type: :array,
                   items: { type: :string, description: 'Resource URI' }
        end

        swagger_schema :DescriptionSetData do
          property :description_sets,
                   type: :array,
                   description: 'Description sets',
                   items: { '$ref': '#/definitions/DescriptionSet' }

          property :resources,
                   type: :array,
                   description: 'Associated resources',
                   items: { '$ref': '#/definitions/Resource' }
        end

        swagger_schema :Graph do
          property :@id,
                   type: :string,
                   description: 'Graph ID'

          property :@graph,
                   type: :array,
                   description: 'Graph resources',
                   items: { '$ref': '#/definitions/Resource' }
        end

        swagger_schema :GroupedDescriptionSets do
          property :ctid,
                   type: :string,
                   description: 'CTID'

          property :description_set,
                   type: :array,
                   items: { '$ref': '#/definitions/DescriptionSet' },
                   description: 'Description sets'
        end

        swagger_schema :EnvelopeDownload do
          property :id,
                   type: :string,
                   description: 'ID'

          property :status,
                   type: :string,
                   description: 'Status (pending, in progress, finished, or failed)'

          property :url,
                   type: :string,
                   description: 'S3 URL (when finished)'
        end

        swagger_schema :RetrieveDescriptionSets do
          property :ctids do
            key :type, :array
            key :description, 'Array of CTIDs'

            items do
              key :type, :string
            end
          end

          property :include_graph_data do
            key :type, :boolean
            key :description, 'Whether to include other resources from the graph'
            key :default, false
          end

          property :include_resources do
            key :type, :boolean
            key :description, 'Whether to include resources alongside description sets'
            key :default, false
          end

          property :include_results_metadata do
            key :type, :boolean
            key :description,
                "Whether to include results' metadata alongside description sets and resources"
            key :default, false
          end

          property :per_branch_limit do
            key :type, :integer
            key :format, :int32
            key :description, 'The number of URIs to be returned'
          end

          property :path_contains do
            key :type, :string
            key :description, 'The string which the returned paths should partially match'
          end

          property :path_exact do
            key :type, :string
            key :description, 'The string which the returned paths should fully match'
          end
        end

        swagger_schema :CtdlSearchResults do
          property :data,
                   description: 'Resources matching the query',
                   type: :array,
                   items: { type: :object }

          property :total,
                   description: 'Total number of results',
                   type: :integer

          property :description_sets,
                   description: 'Description sets grouped by CTIDs',
                   type: :array,
                   items: { '$ref': '#/definitions/GroupedDescriptionSets' }

          property :description_set_resources,
                   description: 'Resources from description sets and/or graph',
                   type: :array,
                   items: { type: :object }

          property :results_metadata,
                   description: 'Results metadata',
                   type: :array,
                   items: { '$ref': '#/definitions/ResultsMetadata' }
        end

        swagger_schema :ResultsMetadata do
          property :resource_uri,
                   description: 'Resource URI',
                   type: :string
          property :'search:recordCreated',
                   description: "Resource's creation data",
                   type: :string,
                   format: :datetime
          property :'search:recordOwnedBy',
                   description: 'CTID of the owning organization',
                   type: :string
          property :'search:recordPublishedBy',
                   description: 'CTID of the publishing organization',
                   type: :string
          property :'search:resourcePublishType',
                   description: "Resource's publish type",
                   type: :string,
                   enum: %w[primary secondary]
          property :'search:recordUpdated',
                   description: "Resource's last modification data",
                   type: :string,
                   format: :datetime
        end
      end
    end
  end
end
