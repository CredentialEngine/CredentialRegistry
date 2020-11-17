class CreatePublishers < ActiveRecord::Migration[4.2]
  def change
    create_table :publishers, id: :uuid do |t|
      t.references :admin, foreign_key: true, null: false
      t.string :contact_info
      t.string :description
      t.string :name, null: false
      t.boolean :super_publisher, default: false, null: false

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        connection.execute(%q{
          CREATE UNIQUE INDEX index_publishers_on_name
          ON publishers(LOWER(name))
        })
      end
    end
  end
end
