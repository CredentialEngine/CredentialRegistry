require 'purge_envelopes'

RSpec.describe PurgeEnvelopes do
  # purged and deleted from the SPARQL index
  let!(:envelope1) { create(:envelope, purged_at: Time.current) }
  # purged, but not deleted from the SPARQL index
  let!(:envelope2) { create(:envelope, purged_at: Time.current) }
  # not purged
  let!(:envelope3) { create(:envelope) }

  describe '.call' do
    before do
      expect(RdfIndexer).to receive(:exists?).with(envelope1).and_return(false)
      expect(RdfIndexer).to receive(:exists?).with(envelope2).and_return(true)
    end

    it 'deletes purged envelopes deleted from the SPARQL index' do
      expect { PurgeEnvelopes.call }.to change { Envelope.count }.by(-1)
      expect { envelope1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { envelope2.reload }.not_to raise_error
      expect { envelope3.reload }.not_to raise_error
    end
  end
end
