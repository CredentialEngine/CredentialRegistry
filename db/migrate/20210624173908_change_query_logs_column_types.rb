class ChangeQueryLogsColumnTypes < ActiveRecord::Migration[5.2]
  def change
    change_column :query_logs, :ctdl, :text
    change_column :query_logs, :result, :text
    change_column :query_logs, :query_logic, :text
  end
end
