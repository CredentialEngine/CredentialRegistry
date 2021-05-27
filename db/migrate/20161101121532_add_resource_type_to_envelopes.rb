class AddResourceTypeToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    change_table(:envelopes) do |t|
      t.string :resource_type, index: true
    end
  end
end
