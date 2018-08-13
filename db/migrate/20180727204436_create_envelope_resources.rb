class CreateEnvelopeResources < ActiveRecord::Migration
  def change
    create_table :envelope_resources do |t|
      t.references :envelope, null: false, index: true, foreign_key: true
      t.string :resource_id, null: false
      t.jsonb :processed_resource, null: false
      t.text :fts_tsearch
      t.column :fts_tsearch_tsv, :tsvector
      t.text :fts_trigram
      t.integer :envelope_type, null: false, default: 0, index: true
      t.string :resource_type, index: true
      t.timestamps null: false, index: true
    end

    add_index :envelope_resources, :processed_resource, using: 'gin'
    add_index :envelope_resources, :fts_tsearch_tsv, using: 'gin'
    add_index :envelope_resources, :resource_id, unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX
            envelope_resources_fts_trigram_idx
          ON
            envelope_resources
          USING
            gin (fts_trigram gin_trgm_ops)
        SQL

        execute <<~SQL
          CREATE TRIGGER
            envelope_resources_fts_tsvector_update
          BEFORE
            INSERT OR UPDATE
          ON
            envelope_resources
          FOR EACH ROW EXECUTE PROCEDURE
            tsvector_update_trigger(fts_tsearch_tsv, 'pg_catalog.simple', fts_tsearch);
        SQL
      end

      dir.down do
        execute 'DROP INDEX envelope_resources_fts_trigram_idx'
        execute 'DROP TRIGGER envelope_resources_fts_tsvector_update ON envelope_resources'
      end
    end
  end

end
