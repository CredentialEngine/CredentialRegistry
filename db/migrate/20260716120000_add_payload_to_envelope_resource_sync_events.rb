class AddPayloadToEnvelopeResourceSyncEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_resource_sync_events, :payload, :jsonb
  end
end
