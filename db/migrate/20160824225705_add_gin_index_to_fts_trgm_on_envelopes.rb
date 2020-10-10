class AddGinIndexToFtsTrgmOnEnvelopes < ActiveRecord::Migration[4.2]
  def up
    execute('CREATE INDEX envelopes_fts_trigram_idx ON envelopes '\
            'USING gin (fts_trigram gin_trgm_ops)')
  end

  def down
    execute("DROP INDEX envelopes_fts_trigram_idx")
  end
end
