class AddStatusToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_downloads, :status, :string, default: 'pending', null: false
  end
end
