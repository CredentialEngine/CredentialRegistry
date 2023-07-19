class CreateEnvelopeDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :envelope_downloads, id: :uuid do |t|
      t.references :envelope_community, null: false
      t.datetime :finished_at
      t.string :internal_error_backtrace, array: true, default: []
      t.string :internal_error_message
      t.datetime :started_at
      t.string :url

      t.timestamps null: false
    end
  end
end
