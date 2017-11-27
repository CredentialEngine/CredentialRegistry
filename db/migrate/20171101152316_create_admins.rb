class CreateAdmins < ActiveRecord::Migration
  def change
    create_table :admins do |t|
      t.string :name, null: false

      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
