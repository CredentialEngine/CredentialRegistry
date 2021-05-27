require 'migration_helpers'

class ChangeScopeOfCtidIndexInEnvelopes < ActiveRecord::Migration[4.2]
  include MigrationHelpers

  def up
    execute 'DROP INDEX index_envelopes_on_envelope_ceterms_ctid'

    execute <<~SQL
      CREATE UNIQUE INDEX
        index_envelopes_on_envelope_community_id_and_envelope_ceterms_ctid
      ON
        envelopes (envelope_community_id, lower(envelope_ceterms_ctid))
      WHERE
        deleted_at IS NULL
    SQL
  end

  def down
    execute 'DROP INDEX index_envelopes_on_envelope_community_id_and_envelope_ceterms_ctid'

    delete_envelopes_with_duplicated_ctids

    execute <<~SQL
      CREATE UNIQUE INDEX
        index_envelopes_on_envelope_ceterms_ctid
      ON
        envelopes (lower(envelope_ceterms_ctid))
      WHERE
        deleted_at IS NULL
    SQL
  end
end
