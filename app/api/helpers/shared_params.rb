# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

  params :delete_envelope do
    requires :delete_token,
             type: String,
             desc: 'Any piece of content signed with the user\'s private key',
             documentation: { param_type: 'body' }
    requires :delete_token_format,
             type: Symbol,
             values: %i(json xml),
             desc: 'Format of the submitted delete token',
             documentation: { param_type: 'body' }
    requires :delete_token_encoding,
             type: Symbol,
             desc: 'Encoding of the submitted delete token',
             values: %i(jwt),
             documentation: { param_type: 'body' }
    requires :delete_token_public_key,
             type: String,
             desc: 'Original key that signed the envelope',
             documentation: { param_type: 'body' }
  end

  params :envelope_id do
    requires :envelope_id, type: String, desc: 'Unique envelope identifier'
  end

  params :envelope_community do
    optional :envelope_community,
             values: -> { EnvelopeCommunity.pluck(:name) },
             default: lambda {
               EnvelopeCommunity.default&.name || 'learning_registry'
             }
  end

  params :pagination do
    optional :page, type: Integer, default: 1, desc: 'Page number'
    optional :per_page, type: Integer, default: 10, desc: 'Items per page'
  end

  def processed_params
    declared(params).to_hash.compact.with_indifferent_access
  end
end
