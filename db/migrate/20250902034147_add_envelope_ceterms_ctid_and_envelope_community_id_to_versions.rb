class AddEnvelopeCetermsCtidAndEnvelopeCommunityIdToVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :envelope_ceterms_ctid, :string
    add_index :versions, :envelope_ceterms_ctid

    add_reference :versions, :envelope_community, foreign_key: { on_delete: :cascade }

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.connection.execute(<<~COMMAND)
          UPDATE versions
          SET envelope_ceterms_ctid = envelopes.envelope_ceterms_ctid,
              envelope_community_id = envelopes.envelope_community_id
          FROM envelopes
          WHERE versions.item_id = envelopes.id
          AND versions.item_type = 'Envelope'
        COMMAND
      end
    end
  end
end
