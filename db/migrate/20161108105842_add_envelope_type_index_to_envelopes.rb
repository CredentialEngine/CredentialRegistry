class AddEnvelopeTypeIndexToEnvelopes < ActiveRecord::Migration[4.2]
  def change
    add_index :envelopes, :envelope_type
  end
end
