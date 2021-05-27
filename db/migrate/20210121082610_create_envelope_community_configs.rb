class CreateEnvelopeCommunityConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :envelope_community_configs do |t|
      t.string :description, null: false
      t.references :envelope_community, foreign_key: true, index: true, null: false
      t.jsonb :payload, default: '{}', null: false
    end
  end
end
