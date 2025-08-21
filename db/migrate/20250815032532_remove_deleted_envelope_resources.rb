class RemoveDeletedEnvelopeResources < ActiveRecord::Migration[8.0]
  def up
    EnvelopeResource.joins(:envelope).where.not(envelopes: { deleted_at: nil }).delete_all
  end
end
