class AddPurgedAtToEnvelopes < ActiveRecord::Migration
  def change
    add_column :envelopes, :purged_at, :datetime
    add_index :envelopes, :purged_at
  end
end
