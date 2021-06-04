class CreateQueryLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :query_logs do |t|
      t.string :engine, index: true, null: false
      t.datetime :started_at, index: true, null: false
      t.datetime :completed_at, index: true
      t.jsonb :ctdl, index: true
      t.jsonb :result, index: true
      t.jsonb :query_logic, index: true
      t.text :query
      t.text :error
    end
  end
end
