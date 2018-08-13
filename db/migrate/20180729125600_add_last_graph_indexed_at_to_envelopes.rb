class AddLastGraphIndexedAtToEnvelopes < ActiveRecord::Migration
  def change
    add_column :envelopes, :last_graph_indexed_at, :datetime, index: true
  end
end
