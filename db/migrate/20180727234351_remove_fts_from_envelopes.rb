class RemoveFtsFromEnvelopes < ActiveRecord::Migration
  def up
    remove_column :envelopes, :fts_tsearch, :text
    remove_column :envelopes, :fts_trigram, :text
    remove_column :envelopes, :fts_tsearch_tsv, :tsvector

    execute <<-SQL
      DROP TRIGGER fts_tsvector_update ON envelopes
    SQL
  end

  def down
    add_column :envelopes, :fts_tsearch, :text
    add_column :envelopes, :fts_tsearch_tsv, :tsvector
    add_column :envelopes, :fts_trigram, :text
    add_index :envelopes, :fts_tsearch_tsv, using: "gin"

    execute <<-SQL
      CREATE INDEX envelopes_fts_trigram_idx ON envelopes
      USING gin (fts_trigram gin_trgm_ops)
    SQL

    execute <<-SQL
      CREATE TRIGGER fts_tsvector_update BEFORE INSERT OR UPDATE
      ON envelopes FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(fts_tsearch_tsv, 'pg_catalog.simple', fts_tsearch);
    SQL
  end
end
