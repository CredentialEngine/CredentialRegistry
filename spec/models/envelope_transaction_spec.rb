require 'envelope_transaction'

describe EnvelopeTransaction, type: :model do
  describe '#dump' do
    it 'dumps an envelope JSON structure suitable for export' do
      transaction = create(:envelope_transaction)
      dump_keys = %i(status date envelope)

      transaction_dump = transaction.dump
      community_name = transaction_dump[:envelope][:envelope_community]

      expect(dump_keys.all? { |s| transaction_dump.key?(s) }).to eq(true)
      expect(community_name).to eq('learning_registry')
    end

    it 'rejects the dump if the transaction has not been persisted' do
      expect do
        transaction = build(:envelope_transaction)

        transaction.dump
      end.to raise_error(LR::TransactionNotPersistedError)
    end
  end
end
