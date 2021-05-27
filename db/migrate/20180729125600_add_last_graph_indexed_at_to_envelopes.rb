class AddLastGraphIndexedAtToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    add_column :envelopes, :last_graph_indexed_at, :datetime, index: true
  end
end
