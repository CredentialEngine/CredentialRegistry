require 'aws-sdk-core'
require 'aws-sigv4'
require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'time'
require 'uri'

class KubernetesServiceAccountTokenRequester
  TOKEN_REFRESH_SKEW_SECONDS = 60

  def initialize(
    api_url:,
    cluster_name:,
    namespace:,
    service_account:,
    audience: 'https://kubernetes.default.svc',
    expiration_seconds: 600,
    region: ENV.fetch('AWS_REGION', 'us-east-1'),
    credentials_provider: Aws::CredentialProviderChain.new.resolve
  )
    @api_url = api_url
    @cluster_name = cluster_name
    @namespace = namespace
    @service_account = service_account
    @audience = audience
    @expiration_seconds = expiration_seconds.to_i
    @region = region
    @credentials_provider = credentials_provider
    @token = nil
    @expires_at = nil
  end

  def token
    return @token if @token && @expires_at && Time.now < @expires_at - TOKEN_REFRESH_SKEW_SECONDS

    refresh_token
  end

  def to_s
    token
  end

  private

  def refresh_token
    response = http.request(request)
    parsed_body = parse_body(response.body)

    unless response.code.to_i.between?(200, 299)
      raise "Kubernetes token request failed: HTTP #{response.code} #{response.message} #{response.body}"
    end

    @token = parsed_body.fetch('status').fetch('token')
    @expires_at = parse_expiration(parsed_body.dig('status', 'expirationTimestamp'))
    @token
  end

  def request
    Net::HTTP::Post.new(token_request_uri).tap do |request|
      request['Authorization'] = "Bearer #{eks_bearer_token}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = JSON.generate(
        apiVersion: 'authentication.k8s.io/v1',
        kind: 'TokenRequest',
        spec: {
          audiences: [@audience],
          expirationSeconds: @expiration_seconds
        }
      )
    end
  end

  def http
    Net::HTTP.new(token_request_uri.host, token_request_uri.port).tap do |http|
      http.use_ssl = token_request_uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def token_request_uri
    @token_request_uri ||= begin
      base_uri = URI.parse(@api_url)
      base_path = base_uri.path.to_s.sub(%r{/+\z}, '')
      base_uri.path = "#{base_path}/api/v1/namespaces/#{@namespace}/serviceaccounts/#{@service_account}/token"
      base_uri.query = nil
      base_uri
    end
  end

  def eks_bearer_token
    presigned_url = sts_signer.presign_url(
      http_method: 'GET',
      url: sts_url,
      headers: {
        'x-k8s-aws-id' => @cluster_name
      },
      expires_in: 60
    ).to_s

    "k8s-aws-v1.#{Base64.urlsafe_encode64(presigned_url).delete('=')}"
  end

  def sts_signer
    @sts_signer ||= Aws::Sigv4::Signer.new(
      service: 'sts',
      region: @region,
      credentials_provider: @credentials_provider
    )
  end

  def sts_url
    "https://sts.#{@region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15"
  end

  def parse_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    raise "Kubernetes token request returned non-JSON response: #{body}"
  end

  def parse_expiration(expiration_timestamp)
    return Time.now + @expiration_seconds unless expiration_timestamp

    Time.parse(expiration_timestamp)
  end
end
