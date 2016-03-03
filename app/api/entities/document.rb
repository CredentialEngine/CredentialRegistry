module API
  module Entities
    # Presenter for Document
    class Document < Grape::Entity
      expose :doc_id
      expose :doc_type
      expose :doc_version
      expose :decoded_envelope, as: :user_envelope
      expose :user_envelope_format
      expose :decoded_node_headers, as: :node_headers
      expose :node_headers_format
      expose :created_at
      expose :updated_at
    end
  end
end
