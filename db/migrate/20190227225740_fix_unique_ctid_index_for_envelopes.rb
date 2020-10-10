class FixUniqueCtidIndexForEnvelopes < ActiveRecord::Migration[4.2]
  def up
    remove_index :envelopes, [:envelope_ceterms_ctid]

    execute <<~SQL
      CREATE UNIQUE INDEX
        index_envelopes_on_envelope_ceterms_ctid
      ON
        envelopes
      USING
        btree (lower(envelope_ceterms_ctid))
      WHERE
        deleted_at IS NULL
    SQL

    execute <<~SQL
      UPDATE
        envelopes
      SET
        envelope_ceterms_ctid = lower(envelope_ceterms_ctid)
      WHERE
        deleted_at is null
    SQL
  end

  def down
    execute "DROP INDEX index_envelopes_on_envelope_ceterms_ctid"
    add_index :envelopes, [:envelope_ceterms_ctid], unique: true, where: 'deleted_at is null'
  end
end
