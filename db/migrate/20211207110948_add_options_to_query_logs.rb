class AddOptionsToQueryLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :query_logs, :options, :jsonb, default: {}, null: false
  end
end
