class AddDeletedAtToDocuments < ActiveRecord::Migration
  def change
    change_table(:documents) { |t| t.datetime :deleted_at }
  end
end
