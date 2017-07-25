class CreateApiConsumers < ActiveRecord::Migration
  def change
    create_table :api_consumers do |t|
      t.string :name
      t.string :email, null: false, index: true
      t.string :provider, null: false
      t.string :uid, null: false, index: true

      t.timestamps null: false
    end
  end
end
