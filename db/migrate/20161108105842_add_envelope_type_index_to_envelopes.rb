class AddEnvelopeTypeIndexToEnvelopes < ActiveRecord::Migration
  def change
    add_index :envelopes, :envelope_type
  end
end
