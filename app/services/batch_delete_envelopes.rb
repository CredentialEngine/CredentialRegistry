# Marks the given envelopes as deleted in a single transaction
class BatchDeleteEnvelopes
  attr_reader :envelopes, :delete_token

  def initialize(envelopes, delete_token)
    @envelopes = envelopes
    @delete_token = delete_token
  end

  def run!
    Envelope.transaction do
      check_token!
      envelopes.map do |envelope|
        envelope.assign_attributes(resource_public_key: delete_token.public_key,
                                   deleted_at: Time.current)
        envelope.save!
      end
    end
  end

  private

  def check_token!
    unless delete_token.valid?
      raise LR::DeleteTokenError.new('Delete token has invalid attributes',
                                     delete_token.errors.full_messages)
    end
  end
end
