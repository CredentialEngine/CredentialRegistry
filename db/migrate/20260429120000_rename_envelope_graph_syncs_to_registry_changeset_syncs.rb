class RenameEnvelopeGraphSyncsToRegistryChangesetSyncs < ActiveRecord::Migration[8.0]
  INDEX_RENAMES = {
    'index_envelope_graph_syncs_on_envelope_community_id' => 'index_registry_changeset_syncs_on_envelope_community_id',
    'index_envelope_graph_syncs_on_last_activity_resource_event_id' =>
      'index_registry_changeset_syncs_on_last_activity_resource_event_id',
    'index_envelope_graph_syncs_on_last_activity_version_id' =>
      'index_registry_changeset_syncs_on_last_activity_version_id',
    'index_envelope_graph_syncs_on_last_synced_resource_event_id' =>
      'index_registry_changeset_syncs_on_last_synced_resource_event_id',
    'index_envelope_graph_syncs_on_last_synced_version_id' =>
      'index_registry_changeset_syncs_on_last_synced_version_id'
  }.freeze

  def up
    rename_table :envelope_graph_syncs, :registry_changeset_syncs
    rename_indexes(INDEX_RENAMES)
    execute 'ALTER INDEX IF EXISTS envelope_graph_syncs_pkey RENAME TO registry_changeset_syncs_pkey'
    execute 'ALTER SEQUENCE IF EXISTS envelope_graph_syncs_id_seq RENAME TO registry_changeset_syncs_id_seq'
  end

  def down
    execute 'ALTER SEQUENCE IF EXISTS registry_changeset_syncs_id_seq RENAME TO envelope_graph_syncs_id_seq'
    execute 'ALTER INDEX IF EXISTS registry_changeset_syncs_pkey RENAME TO envelope_graph_syncs_pkey'
    rename_indexes(INDEX_RENAMES.invert)
    rename_table :registry_changeset_syncs, :envelope_graph_syncs
  end

  private

  def rename_indexes(indexes)
    indexes.each do |from, to|
      rename_index :registry_changeset_syncs, from, to if index_name_exists?(:registry_changeset_syncs, from)
    end
  end
end
