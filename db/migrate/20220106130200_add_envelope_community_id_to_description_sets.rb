class AddEnvelopeCommunityIdToDescriptionSets < ActiveRecord::Migration[6.0]
  def change
    add_column :description_sets, :envelope_community_id, :integer, index: true
  end
end
