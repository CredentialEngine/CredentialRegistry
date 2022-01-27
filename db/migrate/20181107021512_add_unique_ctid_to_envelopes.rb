require 'migration_helpers'

class AddUniqueCtidToEnvelopes < ActiveRecord::Migration[4.2]
  include MigrationHelpers

  def up
    # Fix envelope_ceterms_ctid
    execute <<~SQL
      WITH update_envelope_ids AS (
          SELECT
              e.id
          FROM
              envelopes e
              INNER JOIN envelope_communities ec ON e.envelope_community_id = ec.id
          WHERE
              e.deleted_at IS NULL
              AND ec.name = 'ce_registry'
      )
      UPDATE
          envelopes
      SET
          envelope_ceterms_ctid = reverse(split_part(reverse(processed_resource ->> '@id'), '/', 1))
      WHERE
          id IN (
              SELECT
                  id
              FROM
                  update_envelope_ids)
    SQL

    delete_envelopes_with_duplicated_ctids

    remove_index :envelopes, :envelope_ceterms_ctid
    add_index :envelopes, [:envelope_ceterms_ctid], unique: true, where: 'deleted_at is null'
  end

  def down
    remove_index :envelopes, [:envelope_ceterms_ctid]
  end
end
