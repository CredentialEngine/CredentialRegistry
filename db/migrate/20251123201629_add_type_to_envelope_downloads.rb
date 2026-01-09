class AddTypeToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_downloads, :type, :string, default: 'envelope', null: false
    remove_index :envelope_downloads, :envelope_community_id, unique: true
    add_index :envelope_downloads, %i[envelope_community_id type], unique: true
  end
end
