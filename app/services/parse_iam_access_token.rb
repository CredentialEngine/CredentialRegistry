require 'api_user'

# Verifies and parses a IAM access token
class ParseIAMAccessToken # rubocop:todo Metrics/ClassLength
  attr_reader :encoded_token

  def initialize(encoded_token)
    @encoded_token = encoded_token
  end

  def self.call(encoded_token)
    begin
      JWT.decode(encoded_token, nil, false)
    rescue JWT::DecodeError
      return
    end

    parser = new(encoded_token)

    ApiUser.new(
      community: parser.community,
      roles: parser.roles,
      user: parser.user
    )
  rescue StandardError => e
    raise "IAM: #{e.message}"
  end

  # rubocop:todo Metrics/MethodLength
  def decoded_token # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @decoded_token ||= begin
      # Get the JWKS (JSON Web Key Set) from IAM server
      jwks_uri = build_iam_uri('protocol/openid-connect/certs')
      jwks_response = Net::HTTP.get(jwks_uri)
      jwks = JSON.parse(jwks_response)
      keys = jwks['keys']
      raise "Failed to fetch JWKS (#{jwks_uri})" unless keys

      # Extract the token header to find which key was used
      header_segment = encoded_token.split('.').first
      header = JSON.parse(Base64.decode64(header_segment))
      kid = header['kid']

      # Find the corresponding key in the JWKS
      matching_key = keys.find { it['kid'] == kid }
      raise "No matching key found (#{jwks_uri})" unless matching_key

      # Convert the JWK to a format that the JWT library can use
      jwk = JWT::JWK.new(matching_key)
      public_key = jwk.public_key

      # Verify the token
      JWT.decode(
        encoded_token,
        public_key,
        true,
        {
          algorithm: matching_key['alg'],
          verify_iat: true,
          verify_iss: iam_issuer.present?,
          iss: iam_issuer
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
    value = decoded_token[community_claim_name]
    return value if value.present?

    raise "#{community_claim_name} property is missing in the token"
  end

  def iam_roles
    decoded_token.dig('resource_access', client_id, 'roles') || []
  end

  def roles
    @roles ||= iam_roles.map { role_map[it] }.compact
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

  def build_iam_uri(path)
    uri = URI(iam_realm_url)
    uri.path = File.join(uri.path, path)
    uri
  end

  def client_id
    fetch_env_var('IAM_CLIENT_ID')
  end

  def community_claim_name
    fetch_env_var('IAM_COMMUNITY_CLAIM_NAME')
  end

  def fetch_env_var(name)
    value = ENV.fetch(name, nil)
    return value if value.present?

    raise "#{name} env variable is missing"
  end

  def iam_issuer
    ENV.fetch('IAM_ISSUER', nil)
  end

  def iam_realm_url
    fetch_env_var('IAM_URL')
  end

  def role_map
    {
      fetch_env_var('IAM_COMMUNITY_ROLE_ADMIN') => ApiUser::ADMIN,
      fetch_env_var('IAM_COMMUNITY_ROLE_PUBLISHER') => ApiUser::PUBLISHER,
      fetch_env_var('IAM_COMMUNITY_ROLE_READER') => ApiUser::READER
    }
  end
end
