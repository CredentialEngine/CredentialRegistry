# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

  params :envelope do
    requires :envelope_type, type: String
    requires :envelope_version, type: String
    optional :envelope_id, type: String
    requires :resource, type: String
    requires :resource_format, type: Symbol, values: %i(json xml)
    requires :resource_encoding, type: Symbol, values: %i(jwt)
    optional :resource_public_key, type: String
  end

  params :pagination do
    optional :page, type: Integer, default: 1
    optional :per_page, type: Integer, default: 10
  end

  def processed_params
    declared(params).to_hash.compact
  end
end
