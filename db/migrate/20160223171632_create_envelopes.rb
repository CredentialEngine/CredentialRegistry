class CreateEnvelopes < ActiveRecord::Migration
  def change
    create_table :envelopes do |t|
      t.integer :envelope_type, null: false, default: 0
      t.string :envelope_version, null: false, index: true
      t.string :envelope_id, null: false, index: { unique: true }
      t.text :resource, null: false
      t.integer :resource_format, null: false, default: 0
      t.integer :resource_encoding, null: false, default: 0
      t.text :resource_public_key, null: false
      t.text :node_headers
      t.integer :node_headers_format, default: 0
      t.jsonb :processed_resource, null: false, default: '{}'
      t.datetime :deleted_at

      t.timestamps null: false
    end
    add_index :envelopes, :processed_resource, using: :gin
  end
end
