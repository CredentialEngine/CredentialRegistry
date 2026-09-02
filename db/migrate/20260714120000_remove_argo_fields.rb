class RemoveArgoFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :envelope_downloads, :argo_workflow_name, :string if column_exists?(:envelope_downloads, :argo_workflow_name)
    remove_column :envelope_downloads, :argo_workflow_namespace, :string if column_exists?(:envelope_downloads, :argo_workflow_namespace)
    remove_column :envelope_downloads, :zip_files, :jsonb if column_exists?(:envelope_downloads, :zip_files)
    remove_column :registry_changeset_syncs, :argo_workflows, :jsonb if column_exists?(:registry_changeset_syncs, :argo_workflows)
  end
end
