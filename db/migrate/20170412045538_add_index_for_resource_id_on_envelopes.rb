class AddIndexForResourceIdOnEnvelopes < ActiveRecord::Migration[4.2]
  def up
    execute('CREATE INDEX envelopes_resources_id_idx ON envelopes ' \
            '((processed_resource->>\'@id\'));')
  end

  def down
    execute("DROP INDEX envelopes_resources_id_idx")
  end
end
