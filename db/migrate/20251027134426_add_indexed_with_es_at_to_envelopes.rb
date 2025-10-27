class AddIndexedWithEsAtToEnvelopes < ActiveRecord::Migration[8.0]
  def change
    add_column :envelopes, :indexed_with_es_at, :datetime
    add_index :envelopes, :indexed_with_es_at
  end
end
