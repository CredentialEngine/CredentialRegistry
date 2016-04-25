# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

  params :envelope do
    requires :envelope_type,
             type: String,
             desc: 'Type (currently only resource data)',
             documentation: { param_type: 'body' }
    requires :envelope_version,
             type: String,
             desc: 'Envelope version used',
             documentation: { param_type: 'body' }
    optional :envelope_id,
             type: String,
             desc: 'Global unique identifier',
             documentation: { param_type: 'body' }
    requires :resource,
             type: String,
             desc: 'Learning resource in encoded form',
             documentation: { param_type: 'body' }
    requires :resource_format,
             type: Symbol,
             values: %i(json xml),
             desc: 'Format of the submitted resource',
             documentation: { param_type: 'body' }
    requires :resource_encoding,
             type: Symbol,
             values: %i(jwt),
             desc: 'Encoding of the submitted resource',
             documentation: { param_type: 'body' }
    optional :resource_public_key,
             type: String,
             desc: 'Original public key that signed the envelope',
             documentation: { param_type: 'body' }
  end

  params :pagination do
    optional :page, type: Integer, default: 1, desc: 'Page number'
    optional :per_page, type: Integer, default: 10, desc: 'Items per page'
  end

  def processed_params
    declared(params).to_hash.compact.with_indifferent_access
  end
end
