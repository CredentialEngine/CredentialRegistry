class AddArgoWorkflowsToRegistryChangesetSyncs < ActiveRecord::Migration[8.0]
  def change
    add_column :registry_changeset_syncs, :argo_workflows, :jsonb, null: false, default: []
  end
end
