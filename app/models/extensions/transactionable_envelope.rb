require 'envelope_transaction'

# Takes care of logging all the transactions of a given envelope
module TransactionableEnvelope
  def self.included(base)
    base.class_eval do
      has_many :envelope_transactions, dependent: :delete_all

      after_create -> { log_operation(:created) }
      after_update -> { log_operation(:updated) }
    end
  end

  def log_operation(status)
    transaction_status = deleted_at_changed? ? :deleted : status
    envelope_transactions.create!(status: transaction_status)
  end
end
