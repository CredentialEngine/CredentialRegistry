class AddIndiciesForBulkPurgePerformance < ActiveRecord::Migration[4.2]
  def change
    add_index :envelope_transactions, :envelope_id
    add_index :indexed_envelope_resource_references, :resource_id
    add_index :indexed_envelope_resource_references, :resource_uri
  end
end
