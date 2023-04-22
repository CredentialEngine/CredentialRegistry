# Physically deletes envelopes marked as purged
class PurgeEnvelopes
  def self.call
    Envelope.where.not(purged_at: nil).find_each do |envelope|
      envelope.destroy
    end
  end
end
