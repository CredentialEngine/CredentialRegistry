class AddEnvelopeResourceIdToDescriptionSets < ActiveRecord::Migration[6.0]
  def change
    add_column :description_sets, :envelope_resource_id, :integer
  end
end
