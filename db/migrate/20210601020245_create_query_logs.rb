class CreateQueryLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :query_logs do |t|
      t.string :engine, index: true, null: false
      t.datetime :started_at, index: true, null: false
      t.datetime :completed_at, index: true
      t.jsonb :ctdl
      t.jsonb :result
      t.jsonb :query_logic
      t.text :query
      t.text :error
    end
  end
end
