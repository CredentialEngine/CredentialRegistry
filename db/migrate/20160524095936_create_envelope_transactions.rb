class CreateEnvelopeTransactions < ActiveRecord::Migration[4.2]
  def change
    create_table :envelope_transactions do |t|
      t.integer :status, null: false, default: 0
      t.references :envelope, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
