require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'
require 'v1/single_envelope'
require 'v1/revisions'
require 'v1/resources_pob'

module API
  module V1
    # Implements all the endpoints related to resources
    module ResourceAPI
      # these shenanigans are necessary because a Grape::API can be mounted
      # only once. See https://github.com/ruby-grape/grape/issues/570

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/BlockLength, Metrics/PerceivedComplexity
      def self.included(base)
        base.instance_eval do
          helpers SharedHelpers
          helpers CommunityHelpers
          helpers EnvelopeHelpers

          include API::V1::Defaults
          include API::V1::ResourcesPob

          resource :resources do
            desc 'Publishes a new envelope',
                 http_codes: [
                   { code: 201, message: 'Envelope created' },
                   { code: 200, message: 'Envelope updated' }
                 ]
            params do
              use :update_if_exists
              use :skip_validation
            end
            post do
              params[:envelope_community] = select_community
              envelope, errors = EnvelopeBuilder.new(
                params,
                update_if_exists: update_if_exists?,
                skip_validation: skip_validation?
              ).build

              if errors
                json_error! errors, [:envelope,
                                     envelope.try(:resource_schema_name)]
              else
                present envelope, with: API::Entities::Envelope
                if envelope.created_at != envelope.updated_at
                  status(:ok)
                else
                  status(:created)
                end
              end
            end

            desc 'Return a resource.'
            params do
              requires :id, type: String, desc: 'Resource id.'
            end
            after_validation do
              find_envelope
            end
            get ':id', requirements: { id: /(.*)/i } do
              present @envelope.processed_resource
            end

            desc 'Updates an existing envelope'
            params do
              requires :id, type: String, desc: 'Resource id.'
              use :skip_validation
            end
            after_validation do
              find_envelope
            end
            put ':id', requirements: { id: /(.*)/i } do
              params[:envelope_community] = select_community
              sanitized_params = params.dup
              sanitized_params.delete(:id)
              envelope, errors = EnvelopeBuilder.new(
                sanitized_params,
                envelope:        @envelope,
                skip_validation: skip_validation?
              ).build

              if errors
                json_error! errors, [:envelope, envelope.try(:community_name)]
              else
                present envelope, with: API::Entities::Envelope
              end
            end

            desc 'Marks an existing envelope as deleted'
            params do
              requires :id, type: String, desc: 'Resource id.'
            end
            after_validation do
              find_envelope
              params[:envelope_id] = @envelope.envelope_id
            end
            delete ':id', requirements: { id: /(.*)/i } do
              validator = JSONSchemaValidator.new(params, :delete_envelope)
              if validator.invalid?
                json_error! validator.error_messages, :delete_envelope
              end

              BatchDeleteEnvelopes.new([@envelope],
                                       DeleteToken.new(params)).run!

              body false
              status :no_content
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength, Metrics/PerceivedComplexity
    end
  end
end
