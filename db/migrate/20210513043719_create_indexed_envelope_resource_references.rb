class CreateIndexedEnvelopeResourceReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :indexed_envelope_resource_references do |t|
      t.string :path, null: false

      t.references :resource,
                   foreign_key: {
                     on_delete: :cascade,
                     to_table: :indexed_envelope_resources
                   },
                   index: false,
                   null: false

      t.string :resource_uri, null: false
      t.string :subresource_uri, null: false

      t.foreign_key :indexed_envelope_resources,
                    column: :resource_uri,
                    on_delete: :cascade,
                    primary_key: :'@id'

      t.index %i[path resource_id resource_uri subresource_uri],
              name: 'index_indexed_envelope_resource_references',
              unique: true

      t.index :subresource_uri,
              opclass: { subresource_uri: :gin_trgm_ops },
              using: :gin
    end
  end
end
