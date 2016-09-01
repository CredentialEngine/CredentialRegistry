# Helper class that is responsible for token decoding & verification
class RSADecodedToken
  attr_accessor :token, :public_key
  attr_reader :decoded_token

  def initialize(token, public_key)
    @token = token
    @public_key = public_key
    decode
  end

  def payload
    Hashie::Mash.new(decoded_token.first)
  end

  def decode
    pub_key = OpenSSL::PKey::RSA.new(public_key)
    @decoded_token = JWT.decode token, pub_key, true, algorithm: 'RS256'
  rescue OpenSSL::PKey::RSAError
    raise MetadataRegistry::PkeyError
  rescue JWT::VerificationError, JWT::DecodeError
    raise MetadataRegistry::JWTVerificationError
  end
end
