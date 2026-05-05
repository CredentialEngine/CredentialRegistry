class CreateEnvelopeGraphSyncs < ActiveRecord::Migration[7.1]
  def change
    create_table :envelope_graph_syncs do |t|
      t.references :envelope_community, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_activity_at, null: false
      t.datetime :scheduled_for_at
      t.boolean :syncing, null: false, default: false
      t.datetime :syncing_started_at
      t.datetime :last_sync_finished_at
      t.references :last_activity_version, foreign_key: { to_table: :versions }
      t.references :last_synced_version, foreign_key: { to_table: :versions }
      t.text :last_sync_error
      t.timestamps null: false
    end
  end
end
