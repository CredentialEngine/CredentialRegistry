require 'entities/version'
require 'entities/node_headers'
require 'entities/envelope_community'
require 'entities/payload_formatter'

module API
  module Entities
    # Presenter for EnvelopeResource
    class EnvelopeResource < Grape::Entity
      include PayloadFormatter

      expose :envelope_community,
             using: API::Entities::EnvelopeCommunity,
             merge: true,
             documentation: { type: 'string',
                              desc: 'The community this envelope belongs to' }
      expose :envelope_id,
             documentation: { type: 'string',
                              desc: 'Unique identifier (in UUID format)' }

      expose :envelope_ceterms_ctid,
             documentation: { type: 'string',
                              desc: 'Unique identifier (ceterms:ctid)' }

      expose :envelope_ctdl_type,
             documentation: { type: 'string',
                              desc: 'CTDL Type (@type)' }

      expose :envelope_type,
             documentation: { type: 'string',
                              desc: 'Type (currently only resource data)',
                              values: ['resource_data'] }

      expose :envelope_version,
             documentation: { type: 'string',
                              desc: 'Envelope version used' }

      expose :resource,
             documentation: { type: 'string',
                              desc: 'Learning resource in its original '\
                                    'encoded format' },
             unless: { type: :metadata_only }

      expose :decoded_resource,
             documentation: { type: 'string',
                              desc: 'Learning resource in decoded form' },
             unless: { type: :metadata_only }

      expose :resource_format,
             documentation: { type: 'string',
                              desc: 'Format of the submitted resource',
                              values: %w[json xml] }

      expose :resource_encoding,
             documentation: { type: 'string',
                              desc: 'Encoding of the submitted resource',
                              values: ['jwt'] }

      expose :resource_public_key,
             documentation: { type: 'string',
                              desc: 'Public key from the pair used to sign the resource' }

      expose :publisher_id,
             documentation: { type: 'string',
                              desc: 'Envelope publisher id' }

      expose :secondary_publisher_id,
             safe: true,
             documentation: { type: 'string',
                              desc: 'Envelope secondary publisher id' }

      expose :decoded_node_headers,
             as: :node_headers,
             using: API::Entities::NodeHeaders,
             documentation: { type: 'object',
                              desc: 'Additional headers added by the node' }

      expose :processed_resource,
             as: :inner_resource,
             documentation: { type: 'string',
                              desc: 'The relevant resource inside the envelope' }

      expose :owned_by,
             documentation: { type: 'string',
                              desc: 'Owner of the envelope' }
      expose :published_by,
             documentation: { type: 'string',
                              desc: 'Publisher of the envelope' }

      def envelope_id
        object.envelope.envelope_id
      end

      def envelope_ceterms_ctid
        object.envelope.envelope_ceterms_ctid
      end

      def envelope_ctdl_type
        object.envelope.envelope_ctdl_type
      end

      def envelope_version
        object.envelope.envelope_version
      end

      def decoded_resource
        format_payload(object.envelope.decoded_resource)
      end

      def resource
        object.envelope.resource
      end

      def resource_format
        object.envelope.resource_format
      end

      def resource_encoding
        object.envelope.resource_encoding
      end

      def resource_public_key
        object.envelope.resource_public_key
      end

      def publisher_id
        object.envelope.publisher_id
      end

      def secondary_publisher_id
        object.envelope.secondary_publisher_id
      end

      def decoded_node_headers
        object.envelope.decoded_node_headers
      end

      def owned_by
        object.envelope.organization&._ctid
      end

      def published_by
        object.envelope.publishing_organization&._ctid
      end
    end
  end
end
