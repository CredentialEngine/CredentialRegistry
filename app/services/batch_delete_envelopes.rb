# Marks the given envelopes as deleted in a single transaction
class BatchDeleteEnvelopes
  attr_reader :envelopes, :public_key

  def initialize(envelopes, public_key)
    @envelopes = envelopes
    @public_key = public_key
  end

  def run!
    Envelope.transaction do
      envelopes.map do |envelope|
        envelope.assign_attributes(resource_public_key: public_key,
                                   deleted_at: Time.current)
        envelope.save!
      end
    end
  end
end
