class AddSecuredToEnvelopeCommunities < ActiveRecord::Migration
  def change
    add_column :envelope_communities, :secured, :boolean, default: false, null: false
  end
end
