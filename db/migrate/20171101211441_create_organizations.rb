class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations, id: :uuid do |t|
      t.references :admin, foreign_key: true, null: false
      t.string :description
      t.string :name, null: false

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        connection.execute(%q{
          CREATE UNIQUE INDEX index_organizations_on_name
          ON organizations(LOWER(name))
        })
      end
    end
  end
end
