class AddOcnColumnsToEnvelopeCommunities < ActiveRecord::Migration[7.1]
  def change
    add_column :envelope_communities, :ocn_directory_id, :uuid
    add_column :envelope_communities, :ocn_export_enabled, :boolean, default: false, null: false
    add_column :envelope_communities, :ocn_s3_bucket, :string
  end
end
