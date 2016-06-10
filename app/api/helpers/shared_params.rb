# Reusable parameter groups used in endpoints
module SharedParams
  extend Grape::API::Helpers

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

  def json_error!(errs, schemas = nil, status = :unprocessable_entity)
    schema_urls = Array(schemas).compact.map do |name|
      "#{request.base_url}/api/schemas/#{name}"
    end
    resp = { errors: errs }
    resp[:json_schema] = schema_urls if schema_urls.any?
    error! resp, status
  end
end
