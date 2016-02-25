module API
  module Entities
    # Presenter for Document
    class Document < Grape::Entity
      expose :doc_id
      expose :doc_type
      expose :doc_version
      expose :user_envelope do |document|
        JWT.decode(document.user_envelope, nil, false).first
      end
      expose :user_envelope_format
      expose :node_headers do |document|
        JWT.decode(document.node_headers, nil, false).first
      end
      expose :node_headers_format
      expose :created_at
      expose :updated_at
    end
  end
end
