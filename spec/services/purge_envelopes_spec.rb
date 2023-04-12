require 'purge_envelopes'

RSpec.describe PurgeEnvelopes do
  let!(:envelope1) { create(:envelope, purged_at: Time.current) }
  let!(:envelope2) { create(:envelope, purged_at: Time.current) }
  let!(:envelope3) { create(:envelope) }

  describe '.call' do
    it 'deletes purged envelopes' do
      expect { PurgeEnvelopes.call }.to change { Envelope.count }.by(-2)
      expect { envelope1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { envelope2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { envelope3.reload }.not_to raise_error
    end
  end
end
