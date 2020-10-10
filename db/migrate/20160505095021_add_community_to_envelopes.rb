class AddCommunityToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    change_table(:envelopes) do |t|
      t.references :envelope_community, null: false, foreign_key: true
    end
  end
end
