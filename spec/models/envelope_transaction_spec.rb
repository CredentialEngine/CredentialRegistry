require 'envelope_transaction'

describe EnvelopeTransaction, type: :model do
  describe '#dump' do
    it 'dumps an envelope JSON structure suitable for export' do
      transaction = create(:envelope_transaction)
      keys = %i(envelope_id status date envelope)

      transaction_dump = transaction.dump

      expect(keys.all? { |s| transaction_dump.key?(s) }).to eq(true)
      expect(transaction_dump[:envelope][:envelope_version]).to eq('0.52.0')
    end

    it 'rejects the dump if the transaction has not been persisted' do
      expect do
        transaction = build(:envelope_transaction)

        transaction.dump
      end.to raise_error(LR::TransactionNotPersistedError)
    end
  end
end
