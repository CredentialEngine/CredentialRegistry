require 'helpers/envelope_helpers'

module API
  module V1
    # Implements all the endpoints related to a single envelope
    module SingleEnvelope
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/BlockLength
      def self.included(base)
        base.instance_eval do
          include API::V1::Defaults

          helpers SharedHelpers
          helpers EnvelopeHelpers

          desc 'Retrieves an envelope by identifier',
               entity: API::Entities::Envelope
          params do
            use :envelope_id
          end
          get do
            present @envelope, with: API::Entities::Envelope
          end

          desc 'Updates an existing envelope'
          params do
            use :envelope_id
            use :skip_validation
          end
          patch do
            envelope, errors = EnvelopeBuilder.new(
              params, envelope: @envelope, skip_validation: skip_validation?
            ).build

            if errors
              json_error! errors, [:envelope, envelope.try(:community_name)]

            else
              present envelope, with: API::Entities::Envelope
            end
          end

          desc 'Marks an existing envelope as deleted'
          params do
            use :envelope_id
          end
          delete do
            validator = JSONSchemaValidator.new(params, :delete_envelope)
            if validator.invalid?
              json_error! validator.error_messages, :delete_envelope
            end

            BatchDeleteEnvelopes.new(Array(@envelope),
                                     DeleteToken.new(params)).run!

            body false
            status :no_content
          end

          desc 'Gives general info about the single envelope'
          get :info do
            envelopes_info
          end

          desc 'Updates verification date'
          params do
            use :envelope_id
            requires :last_verified_on, type: Date
          end
          patch 'verify' do
            @envelope.update_column(
              :last_verified_on,
              params[:last_verified_on]
            )

            present @envelope, with: API::Entities::Envelope
          end
        end
      end
    end
  end
end
