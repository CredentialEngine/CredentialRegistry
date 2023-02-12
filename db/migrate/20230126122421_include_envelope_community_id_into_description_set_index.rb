class IncludeEnvelopeCommunityIdIntoDescriptionSetIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :description_sets, %i[ceterms_ctid path]

    add_index :description_sets,
              %i[ceterms_ctid envelope_community_id path],
              name: 'index_description_sets',
              unique: true
  end
end
