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

          swagger_path '/{community_name}/envelopes/download' do
            operation :get do
              key :operationId, 'getApiEnvelopesDownload'
              key :description, "Returns the download's status and URL"
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name

              response 200 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end

            operation :post do
              key :operationId, 'postApiEnvelopesDownloads'
              key :description, 'Starts a new download'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              parameter community_name

              response 201 do
                key :description, 'Download object'
                schema { key :$ref, :EnvelopeDownload }
              end
            end
          end

          swagger_path '/{community_name}/envelopes/events' do
            operation :get do # rubocop:todo Metrics/BlockLength
              key :operationId, 'getApiEnvelopesEvents'
              key :description, 'Retrieves envelope events ordered by date'
              key :produces, ['application/json']
              key :tags, ['Envelopes']

              security

              parameter community_name
              parameter name: :after,
                        in: :query,
                        type: :string,
                        format: :datetime,
                        required: false,
                        description: 'Events that occurred after this date and time'
              parameter name: :ctid,
                        in: :query,
                        type: :string,
                        required: false,
                        description: 'Events of the envelope with this CTID'
              parameter name: :event,
                        in: :query,
                        type: :string,
                        enum: %w[create update destroy],
                        required: false,
                        description: 'Event type'
              parameter provisional(default: 'include')
              parameter page_param
              parameter per_page_param

              response 200 do
                key :description, 'Retrieves envelope events ordered by date'
                schema do
                  key :type, :array
                  items { key :$ref, :EnvelopeEvent }
                end
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
