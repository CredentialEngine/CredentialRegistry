class CreateOrganizationPublishers < ActiveRecord::Migration
  def change
    create_table :organization_publishers do |t|
      t.uuid :organization_id, null: false
      t.uuid :publisher_id, null: false

      t.index %i[organization_id publisher_id], name: 'index_organization_publishers', unique: true

      t.foreign_key :organizations, on_delete: :cascade
      t.foreign_key :publishers, on_delete: :cascade
    end
  end
end
