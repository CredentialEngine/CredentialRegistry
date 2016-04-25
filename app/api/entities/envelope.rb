require 'entities/version'

module API
  module Entities
    # Presenter for Envelope
    class Envelope < Grape::Entity
      expose :envelope_id,
             documentation: { type: 'integer',
                              desc: 'Unique identifier (in UUID format)' }
      expose :envelope_type,
             documentation: { type: 'string',
                              desc: 'Type (currently only resource data)',
                              values: ['resource_data'] }
      expose :envelope_version,
             documentation: { type: 'string',
                              desc: 'Envelope version used' }
      expose :decoded_resource,
             as: :resource,
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
             documentation: { type: 'object',
                              desc: 'Additional headers added by the node' }
      expose :node_headers_format,
             documentation: { type: 'string',
                              desc: 'Format of the node headers',
                              values: ['jwt'] }
      expose :versions,
             unless: :is_version,
             using: API::Entities::Version,
             documentation: { is_array: true,
                              desc: 'Versions belonging to the envelope' }
      expose :created_at,
             documentation: { type: 'dateTime',
                              desc: 'Creation date' }
      expose :updated_at,
             documentation: { type: 'dateTime',
                              desc: 'Last modification date' }
    end
  end
end
