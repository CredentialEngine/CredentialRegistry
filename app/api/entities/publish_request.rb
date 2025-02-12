require 'entities/version'
require 'entities/node_headers'
require 'entities/envelope_community'
require 'entities/payload_formatter'

module API
  module Entities
    # Presenter for Envelope
    class PublishRequest < Grape::Entity
      include PayloadFormatter

      expose :id,
             documentation: { type: 'string',
                              desc: 'Unique identifier (in UUID format)' }

      expose :envelope_id,
             documentation: { type: 'string',
                              # rubocop:todo Layout/LineLength
                              desc: 'Unique identifier (in UUID format) for created or updated envelope' }
      # rubocop:enable Layout/LineLength

      expose :envelope_ceterms_ctid,
             documentation: { type: 'string',
                              # rubocop:todo Layout/LineLength
                              desc: 'Unique identifier (ceterms:ctid) for created or updated envelope' }
      # rubocop:enable Layout/LineLength

      expose :error,
             documentation: { type: 'string',
                              desc: 'Error triggered during publishing process' }

      expose :created_at,
             documentation: { type: 'dateTime',
                              desc: 'Creation date' }

      expose :completed_at,
             documentation: { type: 'dateTime',
                              desc: 'Completion date' }

      expose :status,
             documentation: { type: 'string',
                              desc: 'Status for the request' }

      def envelope_id
        object.envelope&.envelope_id
      end

      def envelope_ceterms_ctid
        object.envelope&.envelope_ceterms_ctid
      end
    end
  end
end
