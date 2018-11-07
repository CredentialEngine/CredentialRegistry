class AddUniqueCtidToEnvelopes < ActiveRecord::Migration
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

    # Fix duplicates
    dupes = Envelope.find_by_sql <<~SQL
      WITH ctid_dupes AS (
          SELECT
              envelope_ceterms_ctid
          FROM
              envelopes
          WHERE
              deleted_at IS NULL
              AND envelope_ceterms_ctid IS NOT NULL
          GROUP BY
              envelope_ceterms_ctid
          HAVING
              count(*) > 1
      ),
      envelope_dupes AS (
          SELECT
              *
          FROM
              envelopes
          WHERE
              envelope_ceterms_ctid IN (
                  SELECT
                      *
                  FROM
                      ctid_dupes)
      ),
      numbered_dupes AS (
          SELECT
              *,
              row_number()
              OVER (PARTITION BY
                      envelope_ceterms_ctid
                  ORDER BY
                      created_at ASC) row_num
              FROM
                  envelope_dupes
      )
      SELECT
          *
      FROM
          numbered_dupes
      WHERE
          row_num > 1
    SQL

    puts "Fixing #{dupes.count} duplicates."
    dupes.each do |envelope|
      envelope.mark_as_deleted!
    end

    add_index :envelopes, [:envelope_ceterms_ctid], unique: true, where: 'deleted_at is null'
  end

  def down
    remove_index :envelopes, [:envelope_ceterms_ctid]
  end
end
