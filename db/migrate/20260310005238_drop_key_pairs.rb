class DropKeyPairs < ActiveRecord::Migration[8.0]
  def up
    drop_table :key_pairs
  end

  def down
    create_table :key_pairs do |t|
      t.binary :encrypted_private_key, null: false
      t.binary :iv, null: false
      t.string :public_key, null: false
      t.integer :status, default: 1, null: false
      t.uuid :organization_id
      t.timestamps null: false
      t.index :public_key, unique: true
    end
    add_foreign_key :key_pairs, :organizations
  end
end
