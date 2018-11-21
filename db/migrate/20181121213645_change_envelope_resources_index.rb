class ChangeEnvelopeResourcesIndex < ActiveRecord::Migration
  def up
    remove_index :envelope_resources, :resource_id

    # No longer have an unique index
    add_index :envelope_resources, :resource_id
  end

  def down
    remove_index :envelope_resources, :resource_id

    execute 'delete from envelope_resources'
    # No longer have an unique index
    add_index :envelope_resources, :resource_id, unique: true
  end
end
