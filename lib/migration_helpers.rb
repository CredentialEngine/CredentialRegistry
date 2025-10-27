require 'envelope'

# Shared code used in migrations
module MigrationHelpers
  def delete_envelopes_with_duplicated_ctids # rubocop:todo Metrics/MethodLength
    dupes = ::Envelope.find_by_sql <<~SQL
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
    dupes.each(&:mark_as_deleted!)
  end
end
