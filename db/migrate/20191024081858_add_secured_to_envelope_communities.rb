class AddSecuredToEnvelopeCommunities < ActiveRecord::Migration[4.2]
  def change
    add_column :envelope_communities, :secured, :boolean, default: false, null: false
  end
end
