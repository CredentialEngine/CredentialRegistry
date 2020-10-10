class CreateKeyPairs < ActiveRecord::Migration[4.2]
  def change
    create_table :key_pairs do |t|
      t.binary :encrypted_private_key, null: false
      t.binary :iv, null: false
      t.references :organization_publisher, foreign_key: true, null: false
      t.string :public_key, null: false
      t.integer :status, default: 1, null: false

      t.timestamps null: false

      t.index :public_key, unique: true
    end
  end
end
