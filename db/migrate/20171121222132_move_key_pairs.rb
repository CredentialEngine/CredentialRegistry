class MoveKeyPairs < ActiveRecord::Migration[4.2]
  def change
    remove_column :key_pairs, :organization_publisher_id, :integer
    add_column :key_pairs, :organization_id, :uuid, index: true
    add_foreign_key :key_pairs, :organizations
  end
end
