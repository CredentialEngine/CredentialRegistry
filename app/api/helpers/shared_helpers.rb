# Reusable parameter groups used in endpoints
module SharedHelpers
  extend Grape::API::Helpers

  params :envelope_id do
    requires :envelope_id, type: String, desc: 'Unique envelope identifier'
  end

  params :envelope_community do
    optional :envelope_community,
             values: -> { EnvelopeCommunity.pluck(:name) }
  end

  params :pagination do
    optional :page, type: Integer, default: 1, desc: 'Page number'
    optional :per_page, type: Integer, default: 10, desc: 'Items per page'
  end

  # Raise an API error.
  #
  # Params:
  #     - errs:    [Array|Hash]   error messages
  #     - schemas: [Array|String] one or more schema_names used for validation
  #     - status:  [Symbol|Int]   status code (default: unprocessable_entity)
  #
  # Response:
  #    {
  #       "errors": [ ... ],       // json formated err messages
  #       "json_schema": [ ... ],  // urls for the json_schemas
  #    }
  def json_error!(errs, schemas = nil, status = :unprocessable_entity)
    schema_names = Array(schemas) << :json_ld
    schema_urls = schema_names.compact.map { |name| url(:api, :schemas, name) }
    resp = { errors: errs }
    resp[:json_schema] = schema_urls if schema_urls.any?
    error! resp, status
  end

  # URL builder
  #
  # Params:
  #   - path: [*String] splat list of string.
  #
  # Return: joined url
  #
  # Example:
  #    uri(:api, :bla, :something) # => 'http://<hostname>/api/bla/something'
  #
  def url(*path)
    ["#{request.scheme}://#{request.host_with_port}", *path].join('/')
  end
end
