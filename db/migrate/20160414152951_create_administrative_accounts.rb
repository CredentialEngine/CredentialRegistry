class CreateAdministrativeAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :administrative_accounts do |t|
      t.string :public_key, null: false, index: { unique: true }

      t.timestamps null: false
    end
  end
end
