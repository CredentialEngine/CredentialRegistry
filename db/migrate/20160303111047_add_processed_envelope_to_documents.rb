class AddProcessedEnvelopeToDocuments < ActiveRecord::Migration
  def change
    change_table(:documents) do |t|
      t.jsonb :processed_envelope, null: false, default: '{}'
    end
    add_index :documents, :processed_envelope, using: :gin
  end
end
