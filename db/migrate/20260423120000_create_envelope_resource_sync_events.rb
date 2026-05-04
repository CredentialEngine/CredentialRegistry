class CreateEnvelopeResourceSyncEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :envelope_resource_sync_events do |t|
      t.references :envelope_community, null: false, foreign_key: true
      t.string :resource_id, null: false
      t.integer :action, null: false

      t.timestamps
    end

    add_index :envelope_resource_sync_events, %i[envelope_community_id id]
    add_index :envelope_resource_sync_events, %i[envelope_community_id resource_id id],
              name: 'idx_resource_sync_events_on_comm_resource_id'

    change_table :envelope_graph_syncs, bulk: true do |t|
      t.bigint :last_activity_resource_event_id
      t.bigint :last_synced_resource_event_id
    end

    add_index :envelope_graph_syncs, :last_activity_resource_event_id
    add_index :envelope_graph_syncs, :last_synced_resource_event_id

    add_foreign_key :envelope_graph_syncs,
                    :envelope_resource_sync_events,
                    column: :last_activity_resource_event_id
    add_foreign_key :envelope_graph_syncs,
                    :envelope_resource_sync_events,
                    column: :last_synced_resource_event_id
  end
end
