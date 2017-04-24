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
        envelope.resource_public_key = delete_token.public_key
        envelope.mark_as_deleted!
      end
    end
  end

  private

  def check_token!
    return if delete_token.valid?

    raise MR::DeleteTokenError.new('Delete token has invalid attributes',
                                   delete_token.errors.full_messages)
  end
end
