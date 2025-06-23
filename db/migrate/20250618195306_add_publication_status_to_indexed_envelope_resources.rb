class AddPublicationStatusToIndexedEnvelopeResources < ActiveRecord::Migration[8.0]
  def change
    add_column :indexed_envelope_resources, :publication_status, :integer, default: 0, null: false
    add_index :indexed_envelope_resources, :publication_status
  end
end
