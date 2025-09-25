class AddEnqueuedAtToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    add_column :envelope_downloads, :enqueued_at, :datetime
  end
end
