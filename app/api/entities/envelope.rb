require 'entities/version'
require 'entities/node_headers'
require 'entities/envelope_community'

module API
  module Entities
    # Presenter for Envelope
    class Envelope < Grape::Entity
      expose :envelope_community,
             using: API::Entities::EnvelopeCommunity,
             merge: true,
             documentation: { type: 'string',
                              desc: 'The community this envelope belongs to' }
      expose :envelope_id,
             documentation: { type: 'string',
                              desc: 'Unique identifier (in UUID format)' }
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
                                    'encoded format' }
      expose :decoded_resource,
             documentation: { type: 'string',
                              desc: 'Learning resource in decoded form' }
      expose :resource_format,
             documentation: { type: 'string',
                              desc: 'Format of the submitted resource',
                              values: %w(json xml) }
      expose :resource_encoding,
             documentation: { type: 'string',
                              desc: 'Encoding of the submitted resource',
                              values: ['jwt'] }
      expose :decoded_node_headers,
             as: :node_headers,
             using: API::Entities::NodeHeaders,
             documentation: { type: 'object',
                              desc: 'Additional headers added by the node' }
    end
  end
end
