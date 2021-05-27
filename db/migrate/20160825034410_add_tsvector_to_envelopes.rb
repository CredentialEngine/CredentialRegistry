class AddTsvectorToEnvelopes < ActiveRecord::Migration[4.2]
  def up
    add_column :envelopes, :fts_tsearch_tsv, :tsvector
    add_index :envelopes, :fts_tsearch_tsv, using: "gin"

    execute <<-SQL
      CREATE TRIGGER fts_tsvector_update BEFORE INSERT OR UPDATE
      ON envelopes FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(fts_tsearch_tsv, 'pg_catalog.simple', fts_tsearch);
    SQL

    # now = Time.current.to_s(:db)
    # update("UPDATE envelopes SET updated_at = '#{now}'")
  end

  def down
    execute <<-SQL
      DROP TRIGGER fts_tsvector_update
      ON envelopes;
    SQL

    remove_index :envelopes, :fts_tsearch_tsv
    remove_column :envelopes, :fts_tsearch_tsv
  end
end
