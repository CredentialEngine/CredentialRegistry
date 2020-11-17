class AddFtsToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    change_table(:envelopes) do |t|
      t.text :fts_tsearch
      t.text :fts_trigram
    end
  end
end
