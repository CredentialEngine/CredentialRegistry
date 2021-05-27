class AddPurgedAtToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    add_column :envelopes, :purged_at, :datetime
    add_index :envelopes, :purged_at
  end
end
