class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :admin, foreign_key: true
      t.string :email, null: false
      t.uuid :publisher_id

      t.timestamps null: false

      t.index :publisher_id

      t.foreign_key :publishers
    end

    reversible do |dir|
      dir.up do
        connection.execute(%q{
          CREATE UNIQUE INDEX index_users_on_email
          ON users(LOWER(email))
        })
      end
    end
  end
end
