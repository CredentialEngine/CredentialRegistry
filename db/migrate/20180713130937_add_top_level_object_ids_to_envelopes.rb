class AddTopLevelObjectIdsToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    add_column :envelopes, :top_level_object_ids, :text, array: true, default: []
    add_index  :envelopes, :top_level_object_ids, using: 'gin'

    reversible do |dir|
      dir.up do
        execute <<~SQL
          WITH
            envelope_ctids
          AS (
            SELECT
              id, array_agg(distinct(ctid)) as ctids
            FROM (
              SELECT
                id, lower(value->>'ceterms:ctid') as ctid
              FROM
                envelopes, jsonb_array_elements(processed_resource->'@graph')
              WHERE
                processed_resource ? '@graph'
              UNION
              SELECT
                id, lower(processed_resource->>'ceterms:ctid') as ctid
              FROM
                envelopes
            ) ctids
            GROUP BY id
          )
          UPDATE
            envelopes
          SET
            top_level_object_ids = envelope_ctids.ctids
          FROM
            envelope_ctids
          WHERE
            envelope_ctids.id = envelopes.id
        SQL
      end
    end
  end
end
