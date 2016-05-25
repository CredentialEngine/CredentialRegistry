require 'envelope_transaction'

# Takes care of logging all the transactions of a given envelope
module TransactionableEnvelope
  def self.included(base)
    base.class_eval do
      has_many :envelope_transactions

      after_create -> { log_operation(:created) }
      after_update -> { log_operation(:updated) }
    end
  end

  def log_operation(status)
    envelope_transactions.create!(status: status)
  end
end
