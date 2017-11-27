class MoveKeyPairs < ActiveRecord::Migration
  def change
    remove_column :key_pairs, :organization_publisher_id
    add_column :key_pairs, :organization_id, :uuid, index: true
    add_foreign_key :key_pairs, :organizations
  end
end
