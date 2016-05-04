class CreateEnvelopeCommunities < ActiveRecord::Migration
  def change
    create_table :envelope_communities do |t|
      t.string :name, null: false, index: { unique: true }
      t.boolean :default, null: false, default: false

      t.timestamps null: false
    end
  end
end
