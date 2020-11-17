class CreateAuthTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :auth_tokens do |t|
      t.integer :user_id
      t.string :value, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :value, unique: true

      t.foreign_key :users, on_delete: :cascade
    end
  end
end
