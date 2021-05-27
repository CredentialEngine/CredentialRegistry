class AddSecondaryPublisher < ActiveRecord::Migration[4.2]
  def change
    add_column :envelopes, :secondary_publisher_id, :uuid, index: true
    add_foreign_key :envelopes, :publishers, column: :secondary_publisher_id
  end
end
