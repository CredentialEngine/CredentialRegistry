class AddLastPublishedAtToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_downloads, :last_published_at, :datetime
  end
end
