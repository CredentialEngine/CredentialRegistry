module MetadataRegistry
  class SwaggerDocs
    module Sections
      # rubocop:todo Style/Documentation
      module Envelopes # rubocop:todo Metrics/ModuleLength, Style/Documentation
        # rubocop:enable Style/Documentation
        extend ActiveSupport::Concern

        included do
          swagger_path '/{community_name}/envelopes' do
            operation :get do
              key :operationId, 'getApiEnvelopes'
              key :description, 'Retrieves all community envelopes ordered by date'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter metadata_only
              parameter page_param
              parameter per_page_param
              parameter provisional

              response 200 do
                key :description, 'Retrieves all envelopes ordered by date'
                schema do
                  key :type, :array
                  items { key :$ref, :Envelope }
                end
              end
            end

            operation :post do # rubocop:todo Metrics/BlockLength
              key :operationId, 'postApiEnvelopes'
              key :description, 'Publishes a new envelope'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter name: :update_if_exists,
                        in: :query,
                        type: :boolean,
                        required: false,
                        description: 'Whether to update the envelope if exists'
              parameter name: :owned_by,
                        in: :query,
                        type: :string,
                        required: false,
                        description: 'The CTID of the owning organization'
              parameter published_by
              parameter request_envelope

              response 200 do
                key :description, 'Envelope updated'
                schema { key :$ref, :Envelope }
              end
              response 201 do
                key :description, 'Envelope created'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end

            operation :put do
              key :operationId, 'putApiEnvelopes'
              key :description, 'Marks envelopes as deleted'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter delete_envelope_token

              response 204 do
                key :description, 'Matching envelopes marked as deleted'
              end
              response 404 do
                key :description, 'No envelopes match the envelope_id'
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end

            operation :delete do
              key :operationId, 'deleteEnvelopes'
              key :description, 'Purges envelopes published by the given publisher'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter published_by(required: true)
              parameter resource_type
              parameter name: :from,
                        in: :query,
                        type: :string,
                        required: false,
                        description: 'Datetime after which envelopes were publisher'
              parameter name: :until,
                        in: :query,
                        type: :string,
                        required: false,
                        description: 'Datetime before which envelopes were publisher'

              response 204 do
                key :description, 'Successfully purged selected envelopes'
              end
            end
          end

          swagger_path '/{community_name}/envelopes/downloads' do
            operation :post do
              key :operationId, 'postApiEnvelopesDownloads'
              key :description, 'Starts new download'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name

              response 201 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/downloads/{id}' do
            operation :get do
              key :operationId, 'getApiEnvelopesDownloads'
              key :description, "Returns download's status and URL"
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name
              parameter name: :id,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'Download ID'

              response 200 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/info' do
            operation :get do
              key :operationId, 'getApiEnvelopesInfo'
              key :description, 'Gives general info about this community envelopes'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name

              response 200 do
                key :description, 'Gives general info about this community envelopes'
                schema { key :$ref, :EnvelopesInfo }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/{envelope_id}' do
            operation :get do
              key :operationId, 'getApiSingleEnvelope'
              key :description, 'Retrieves an envelope by identifier'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter envelope_id
              parameter include_deleted

              response 200 do
                key :description, 'Retrieves an envelope by identifier'
                schema { key :$ref, :Envelope }
              end
            end

            operation :patch do
              key :operationId, 'patchApiSingleEnvelope'
              key :description, 'Updates an existing envelope'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter envelope_id
              parameter request_envelope

              response 200 do
                key :description, 'Updates an existing envelope'
                schema { key :$ref, :Envelope }
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end

            operation :delete do
              key :operationId, 'deleteApiSingleEnvelope'
              key :description, 'Marks an existing envelope as deleted'
              key :produces, ['application/json']
              key :consumes, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name
              parameter envelope_id
              parameter delete_token

              response 204 do
                key :description, 'Marks an existing envelope as deleted'
              end
              response 422 do
                key :description, 'Validation Error'
                schema { key :$ref, :ValidationError }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/{envelope_id}/info' do
            operation :get do
              key :operationId, 'getApiSingleEnvelopeInfo'
              key :description, 'Gives general info about the single envelope'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter envelope_id
              parameter include_deleted

              response 200 do
                key :description, 'General info about this metadata community'
                schema { key :$ref, :SingleEnvelopeInfo }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/{envelope_id}/revisions/{revision_id}' do
            operation :get do
              key :operationId, 'getApiEnvelopeVersion'
              key :description, 'Retrieves a specific envelope revision'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter envelope_id
              parameter include_deleted
              parameter name: :revision_id,
                        in: :path,
                        type: :string,
                        required: true,
                        description: 'Unique revision identifier'

              response 200 do
                key :description, 'Retrieves a specific envelope revision'
                schema { key :$ref, :Envelope }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/{envelope_id}/verify' do
            operation :patch do
              key :operationId, 'patchApiVerifyEnvelope'
              key :description, 'Updates verification date'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name
              parameter envelope_id

              parameter do
                key :name, :body
                key :in, :body
                key :description, 'JSON object containing last_verified_on'
                key :required, true

                schema do
                  key :type, :object
                  property :last_verified_on do
                    key :type, :string
                    key :format, :date
                    key :description, 'Last verification date'
                    key :example, '2023-07-20'
                  end
                end
              end

              response 200 do
                key :description, 'Retrieves a specific envelope revision'
                schema { key :$ref, :Envelope }
              end
            end
          end
        end
      end
    end
  end
end
