class CreateAdministrativeAccounts < ActiveRecord::Migration
  def change
    create_table :administrative_accounts do |t|
      t.string :public_key, null: false, index: { unique: true }

      t.timestamps null: false
    end
  end
end
