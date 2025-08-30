require 'helpers/envelope_helpers'

module API
  module V1
    # Implements all the endpoints related to a single envelope
    module SingleEnvelope
      # rubocop:todo Lint/MissingCopEnableDirective
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Lint/MissingCopEnableDirective
      # rubocop:todo Lint/MissingCopEnableDirective
      # rubocop:disable Metrics/BlockLength
      # rubocop:enable Lint/MissingCopEnableDirective
      def self.included(base)
        base.instance_eval do
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
