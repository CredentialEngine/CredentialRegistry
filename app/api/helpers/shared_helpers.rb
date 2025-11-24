require 'api_user'
require 'auth_token'
require 'parse_iam_access_token'
require 'validate_api_key'

# Reusable helpers used in endpoints
module SharedHelpers
  extend Grape::API::Helpers

  params :envelope_id do
    requires :envelope_id, type: String, desc: 'Unique envelope identifier'
  end

  params :envelope_community do
    optional :envelope_community,
             values: -> { EnvelopeCommunity.pluck(:name) }
  end

  # duplicate of `:envelope_community` with a different name
  # in order to identify a clash between the url parameter and the body
  # parameter.
  # This should be consolidated e.g. by changing the parameter for the
  # /envelopes endpoint
  params :community_name do
    optional :community_name, values: -> { EnvelopeCommunity.pluck(:name) }
  end

  params :pagination do
    optional :page, type: Integer, default: 1, desc: 'Page number'
    optional :per_page, type: Integer, default: 10, desc: 'Items per page'
  end

  params :update_if_exists do
    optional :update_if_exists,
             type: Grape::API::Boolean,
             desc: 'Whether to update the envelope if it already exists',
             documentation: { param_type: 'query' }
  end

  params :metadata_only do
    optional :metadata_only, type: Grape::API::Boolean, default: false
  end

  params :provisional do
    optional :provisional,
             default: 'exclude',
             values: %w[exclude include only],
             desc: 'Whether to include provisional records',
             documentation: { param_type: 'query' }
  end

  def update_if_exists?
    @update_if_exists ||= params.delete(:update_if_exists)
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
    schema_names = Array(schemas)
    schema_urls = schema_names.compact.map { |name| url(:schemas, name) }
    resp = { errors: errs }
    resp[:json_schema] = schema_urls if schema_urls.any?
    error! resp, status
  end

  def log_backtrace(e) # rubocop:todo Naming/MethodParameterName
    MR.logger.error("\n#{e.backtrace.join("\n")}\n")
  end

  # URL builder
  #
  # Params:
  #   - path: [*String] splat list of string.
  #
  # Return: joined url
  #
  # Example:
  #    uri(:bla, :something) # => 'http://<hostname>/bla/something'
  #
  def url(*path)
    ["#{request.scheme}://#{request.host_with_port}", *path].join('/')
  end

  # Set envelope_community to always be 'underscored' if present.
  # i.e: "Learning-registry" => "learning_registry"
  def normalize_envelope_community
    return unless params[:envelope_community].present?

    params[:envelope_community] = community
  end

  # Get the community name from the params
  # Return: [String] community name
  def community
    params[:envelope_community].try(:underscore)
  end

  def test_response
    {}
  end

  def authenticate!
    auth_required = ActiveRecord::Type::Boolean.new.deserialize(
      ENV.fetch('AUTHENTICATION_REQUIRED', nil)
    )

    return if !auth_required && request.request_method == 'GET'
    return if current_user

    json_error!(['Invalid token'], nil, 401)
  rescue StandardError => e
    json_error!([e.message], nil, 401)
  end

  def authenticate_community!(flag = :secured?)
    community = EnvelopeCommunity.find_by(name: params[:envelope_community])
    return unless community&.send(flag)

    auth_header = request.headers['Authorization']
    api_key = auth_header.split.last if auth_header.present?
    return if api_key.present? && ValidateApiKey.call(api_key, community)

    json_error!(['401 Unauthorized'], nil, 401)
  end

  def current_user
    @current_user ||= begin
      auth_header = request.headers['Authorization']
      token = auth_header.split.last if auth_header.present?

      if token.present?
        if (user = AuthToken.find_by(value: token)&.user)
          ApiUser.new(
            community: current_community,
            roles: [user.admin ? ApiUser::SUPERADMIN : ApiUser::PUBLISHER],
            user:
          )
        else
          ParseIAMAccessToken.call(token)
        end
      end
    end
  end

  def current_user_community
    current_user.community
  end
end
