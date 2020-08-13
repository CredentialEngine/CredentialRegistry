class AddSecuredSearchToEnvelopeCommunities < ActiveRecord::Migration[4.2]
  def change
    add_column :envelope_communities, :secured_search, :boolean, default: false, null: false
  end
end
