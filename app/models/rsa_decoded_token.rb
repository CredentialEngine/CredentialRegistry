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
    @decoded_token = JWT.decode token,
                                OpenSSL::PKey::RSA.new(public_key),
                                true,
                                algorithm: 'RS256'
  end
end
