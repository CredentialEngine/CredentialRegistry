class AddUniqueIndexOnResourceIdToEnvelopeResources < ActiveRecord::Migration[7.1]
  def change
    add_column :envelope_resources, :deleted_at, :datetime
    add_index :envelope_resources, :deleted_at

    add_reference :envelope_resources, :envelope_community, foreign_key: { on_delete: :cascade }

    remove_index :envelope_resources, :resource_id

    reversible do |dir|
      dir.up do
        connection.execute <<~SQL
          CREATE OR REPLACE FUNCTION update_envelope_resources_community_id()
          RETURNS TRIGGER AS
          $$
          BEGIN
            UPDATE envelope_resources
            SET envelope_community_id = NEW.envelope_community_id
            WHERE envelope_id = NEW.id;
            RETURN NEW;
          END
          $$
          LANGUAGE 'plpgsql'
        SQL

        connection.execute <<~SQL
          CREATE OR REPLACE FUNCTION update_envelope_resources_deleted_at()
          RETURNS TRIGGER AS
          $$
          BEGIN
            UPDATE envelope_resources
            SET deleted_at = NEW.deleted_at
            WHERE envelope_id = NEW.id;
            RETURN NEW;
          END
          $$
          LANGUAGE 'plpgsql'
        SQL

        connection.execute <<~SQL
          CREATE TRIGGER update_resources_after_envelopes_community_id_changes
          AFTER UPDATE OF envelope_community_id ON envelopes
          FOR EACH ROW
          EXECUTE FUNCTION update_envelope_resources_community_id();
        SQL

        connection.execute <<~SQL
          CREATE TRIGGER update_resources_after_envelopes_delete_at_changes
          AFTER UPDATE OF deleted_at ON envelopes
          FOR EACH ROW
          EXECUTE FUNCTION update_envelope_resources_deleted_at();
        SQL

        connection.execute <<~SQL
          UPDATE envelope_resources
          SET deleted_at = envelopes.deleted_at,
              envelope_community_id = envelopes.envelope_community_id
          FROM (
            SELECT id, deleted_at, envelope_community_id
            FROM envelopes
          ) envelopes
          WHERE envelope_id = envelopes.id
        SQL

        connection.execute <<~SQL
          CREATE UNIQUE INDEX index_envelope_resources_on_resource_id
          ON envelope_resources (deleted_at, envelope_community_id, resource_id) NULLS NOT DISTINCT
        SQL
      end

      dir.down do
        remove_index :envelope_resources, name: 'index_envelope_resources_on_resource_id'

        connection.execute('DROP TRIGGER update_resources_after_envelopes_community_id_changes ON envelopes')
        connection.execute('DROP TRIGGER update_resources_after_envelopes_delete_at_changes ON envelopes')
        connection.execute('DROP FUNCTION update_envelope_resources_community_id()')
        connection.execute('DROP FUNCTION update_envelope_resources_deleted_at()')
      end
    end
  end
end
