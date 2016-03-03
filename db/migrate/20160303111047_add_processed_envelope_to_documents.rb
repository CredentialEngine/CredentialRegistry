class AddProcessedEnvelopeToDocuments < ActiveRecord::Migration
  def change
    change_table(:documents) do |t|
      t.jsonb :processed_envelope, null: false, default: '{}'
    end
  end
end
