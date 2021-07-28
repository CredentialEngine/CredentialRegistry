class CreatePublishRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :publish_requests do |t|
      t.text :request_params, null: false
      t.references :envelope, null: true, index: true, foreign_key: true
      t.jsonb :error, index: true
      t.datetime :completed_at, index: true
      t.timestamps null: false, index: true
    end
  end
end
