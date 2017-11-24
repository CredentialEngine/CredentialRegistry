module MR
  # Base exception class that allows passing an errors object
  class BaseError < StandardError
    attr_accessor :errors

    def initialize(message = nil, errors = nil)
      super(message)
      self.errors = errors
    end
  end

  class DeleteTokenError < BaseError; end
  class TransactionNotPersistedError < BaseError; end
  class BackupItemMissingError < BaseError; end
  class SchemaDoesNotExist < BaseError; end

  # Encapsulates OpenSSL::PKey::RSAError to be more meaningfull
  class PkeyError < BaseError
    def initialize(message = nil, errors = nil)
      message ||= 'Invalid public_key. Should be a RSA key in PEM format.'
      super(message, errors)
    end
  end

  # Encapsulates JWT::VerificationError to be more meaningfull
  class JWTVerificationError < BaseError
    def initialize(message = nil, errors = nil)
      message ||= 'JWT token failed verification. The token must be encoded '\
                  'using RS256. Also the private key, used for encoding, and '\
                  'the public_key provided must be from the same RSA pair.'
      super(message, errors)
    end
  end

  # We can use only authorized public keys for json_schema envelopes
  class UnauthorizedKey < BaseError
    def initialize(message = nil, errors = nil)
      message ||= 'Unauthorized public_key. Please contact an administrator.'
      super(message, errors)
    end
  end
end
