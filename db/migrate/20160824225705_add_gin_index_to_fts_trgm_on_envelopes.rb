class AddGinIndexToFtsTrgmOnEnvelopes < ActiveRecord::Migration
  def up
    execute('CREATE INDEX envelopes_fts_trgm_idx ON envelopes '\
            'USING gin (fts_trgm gin_trgm_ops)')
  end

  def down
    execute("DROP INDEX envelopes_fts_trgm_idx")
  end
end
