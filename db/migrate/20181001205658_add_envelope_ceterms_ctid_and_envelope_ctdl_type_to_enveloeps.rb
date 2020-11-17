class AddEnvelopeCetermsCtidAndEnvelopeCtdlTypeToEnveloeps < ActiveRecord::Migration[4.2]
  def change
    change_table :envelopes do |t|
      t.string :envelope_ceterms_ctid, index: true
      t.string :envelope_ctdl_type, index: true
    end

    execute <<~SQL
      UPDATE
        envelopes
      SET
        envelope_ceterms_ctid = processed_resource->>'ceterms:ctid',
        envelope_ctdl_type = processed_resource->>'@type'
    SQL
  end
end
