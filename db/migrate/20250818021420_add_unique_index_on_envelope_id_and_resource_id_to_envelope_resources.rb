class AddUniqueIndexOnEnvelopeIdAndResourceIdToEnvelopeResources < ActiveRecord::Migration[8.0]
  def change
    add_index :envelope_resources, %i[envelope_id resource_id], unique: true
  end
end
