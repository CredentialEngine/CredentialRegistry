class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.integer :doc_type, null: false, default: 0
      t.string :doc_version, null: false, index: true
      t.string :doc_id, null: false, index: { unique: true }
      t.text :user_envelope, null: false
      t.integer :user_envelope_format, null: false, default: 0
      t.text :node_headers
      t.integer :node_headers_format, default: 0

      t.timestamps null: false
    end
  end
end
