class AddResourceTypeToEnvelopes < ActiveRecord::Migration
  def change
    change_table(:envelopes) do |t|
      t.string :resource_type, index: true
    end
  end
end
