class AddPublicationStatusToVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :publication_status, :integer, default: 0, null: false
    add_index :versions, :publication_status
  end
end
