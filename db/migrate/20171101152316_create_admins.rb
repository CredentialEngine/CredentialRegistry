class CreateAdmins < ActiveRecord::Migration[4.2]
  def change
    create_table :admins do |t|
      t.string :name, null: false

      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
