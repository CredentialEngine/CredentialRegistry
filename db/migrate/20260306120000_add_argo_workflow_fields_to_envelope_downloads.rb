class AddArgoWorkflowFieldsToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_downloads, :argo_workflow_name, :string
    add_column :envelope_downloads, :argo_workflow_namespace, :string
    add_column :envelope_downloads, :zip_files, :jsonb, default: [], null: false
  end
end
