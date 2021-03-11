class ChangeEnvelopeForeignKeysOnDelete < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :envelope_resources, :envelopes
    add_foreign_key :envelope_resources, :envelopes, on_delete: :cascade

    remove_foreign_key :envelope_transactions, :envelopes
    add_foreign_key :envelope_transactions, :envelopes, on_delete: :cascade
  end
end
