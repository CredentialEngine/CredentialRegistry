# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

  params :document do
    requires :doc_type, type: String
    requires :doc_version, type: String
    optional :doc_id, type: String
    requires :user_envelope, type: String
    requires :user_envelope_format, type: String
    requires :node_headers, type: String
    requires :node_headers_format, type: String
  end
end
