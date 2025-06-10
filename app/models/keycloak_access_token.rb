require 'api_user'

# Verifies and parses a Keycloak access token
class KeycloakAccessToken
  attr_reader :encoded_token

  def initialize(encoded_token)
    @encoded_token = encoded_token
  end

  # rubocop:todo Metrics/MethodLength
  def decoded_token # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    validate!

    @decoded_token ||= begin
      # 1. Get the JWKS (JSON Web Key Set) from Keycloak
      jwks_uri = build_keycloak_uri('protocol/openid-connect/certs')
      jwks_response = Net::HTTP.get(jwks_uri)
      jwks = JSON.parse(jwks_response)
      keys = jwks['keys']
      raise 'Failed to fetch JWKS' unless keys

      # 2. Extract the token header to find which key was used
      header_segment = encoded_token.split('.').first
      header = JSON.parse(Base64.decode64(header_segment))
      kid = header['kid']

      # 3. Find the corresponding key in the JWKS
      matching_key = keys.find { _1['kid'] == kid }
      raise 'No matching key found' unless matching_key

      # 4. Convert the JWK to a format that the JWT library can use
      jwk = JWT::JWK.new(matching_key)
      public_key = jwk.public_key

      # 5. Verify the token
      JWT.decode(
        encoded_token,
        public_key,
        true,
        {
          algorithm: matching_key['alg'],
          verify_iat: true,
          verify_iss: true,
          iss: keycloak_realm_url
        }
      )[0]
    end
  end
  # rubocop:enable Metrics/MethodLength

  def community
    @community ||= EnvelopeCommunity
                   .create_with(secured: false, secured_search: true)
                   .find_or_create_by!(name: community_name)
  end

  def community_name
    value = decoded_token[token_claim_name]
    return value if value.present?

    raise "`#{token_claim_name}` property is missing in the token"
  end

  def keycloak_roles
    decoded_token.fetch('aud').flat_map do |client|
      decoded_token.dig('resource_access', client, 'roles') || []
    end
  end

  def roles
    @roles ||= keycloak_roles.map { role_map[_1] }.compact
  end

  def user
    @user ||= begin
      name = decoded_token.fetch('azp')
      user = User.find_or_initialize_by(email: name)

      if user.new_record?
        admin = Admin.find_or_create_by!(name:)
        publisher = admin.publishers.find_or_create_by!(name:)
        user.update!(admin:, publisher:)
      end

      user
    end
  end

  private

  def build_keycloak_uri(path)
    uri = URI(keycloak_realm_url)
    uri.path = File.join(uri.path, path)
    uri
  end

  def keycloak_realm_url
    ENV.fetch('IAM_URL')
  end

  def role_map
    {
      ENV.fetch('IAM_COMMUNITY_ROLE_ADMIN', nil) => ApiUser::ADMIN,
      ENV.fetch('IAM_COMMUNITY_ROLE_READER', nil) => ApiUser::READER,
      ENV.fetch('IAM_COMMUNITY_ROLE_WRITER', nil) => ApiUser::PUBLISHER
    }
  end

  def token_claim_name
    value = ENV.fetch('IAM_COMMUNITY_CLAIM_NAME', nil)
    return value if value.present?

    raise 'IAM_COMMUNITY_CLAIM_NAME env variable is missing'
  end

  def validate!
    JWT.decode(encoded_token, nil, false)
  end
end
