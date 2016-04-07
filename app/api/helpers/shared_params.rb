# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

  params :document do
    requires :doc_type, type: String
    requires :doc_version, type: String
    optional :doc_id, type: String
    requires :user_envelope, type: String
    requires :user_envelope_format, type: Symbol, values: %i(json xml)
  end

  params :pagination do
    optional :page, type: Integer, default: 1
    optional :per_page, type: Integer, default: 10
  end

  def processed_params
    declared(params).to_hash.compact
  end
end
