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
end
