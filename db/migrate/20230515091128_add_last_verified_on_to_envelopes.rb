class AddLastVerifiedOnToEnvelopes < ActiveRecord::Migration[7.0]
  def change
    add_column :envelopes, :last_verified_on, :date
  end
end
