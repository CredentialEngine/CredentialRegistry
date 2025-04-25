class Secrets
  ENCRYPTED_PRIVATE_KEY_SECRET = SecureRandom.hex

  class << self
    def private_key
      rsa_key.to_pem
    end

    def public_key
      rsa_key.public_key.to_pem
    end

    def rsa_key
      @rsa_key ||= OpenSSL::PKey::RSA.new(2048)
    end
  end
end
