require 'purge_envelopes'

RSpec.describe PurgeEnvelopes do
  let!(:envelope1) { create(:envelope, purged_at: Time.current) } # rubocop:todo RSpec/IndexedLet
  let!(:envelope2) { create(:envelope, purged_at: Time.current) } # rubocop:todo RSpec/IndexedLet
  let!(:envelope3) { create(:envelope) } # rubocop:todo RSpec/IndexedLet

  describe '.call' do
    it 'deletes purged envelopes' do # rubocop:todo RSpec/MultipleExpectations
      expect { described_class.call }.to change(Envelope, :count).by(-2)
      expect { envelope1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { envelope2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { envelope3.reload }.not_to raise_error
    end
  end
end
