class AddLowercaseIndexToEnvelopeResourceIds < ActiveRecord::Migration
  def up
    execute("DROP INDEX envelopes_resources_id_idx")
    execute('CREATE INDEX envelopes_resources_id_idx ON envelopes ' \
            '(lower((processed_resource->>\'@id\')));')
  end

  def down
    execute("DROP INDEX envelopes_resources_id_idx")
    execute('CREATE INDEX envelopes_resources_id_idx ON envelopes ' \
            '((processed_resource->>\'@id\'));')
  end
end
