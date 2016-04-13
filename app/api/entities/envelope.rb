require 'entities/version'

module API
  module Entities
    # Presenter for Envelope
    class Envelope < Grape::Entity
      expose :envelope_id
      expose :envelope_type
      expose :envelope_version
      expose :decoded_resource, as: :resource
      expose :resource_format
      expose :resource_encoding
      expose :decoded_node_headers, as: :node_headers
      expose :node_headers_format
      expose :versions, unless: :is_version, using: API::Entities::Version
      expose :created_at
      expose :updated_at
    end
  end
end
