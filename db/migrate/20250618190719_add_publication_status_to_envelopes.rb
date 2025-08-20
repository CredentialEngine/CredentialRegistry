class AddPublicationStatusToEnvelopes < ActiveRecord::Migration[8.0]
  def change
    add_column :envelopes, :publication_status, :integer, default: 0, null: false
    add_index :envelopes, :publication_status
  end
end
