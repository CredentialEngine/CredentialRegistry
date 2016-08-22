require 'envelope_transaction'

describe EnvelopeTransaction, type: :model do
  describe '#dump' do
    it 'returns a Base64 encoded representation' do
      transaction = create(:envelope_transaction)

      dump = transaction.dump

      expect_base64(dump)
    end

    it 'dumps an envelope JSON structure suitable for export' do
      transaction = create(:envelope_transaction)
      dump_keys = %i(status date envelope)

      dump = JSON.parse(Base64.urlsafe_decode64(transaction.dump))
                 .with_indifferent_access
      community_name = dump[:envelope][:envelope_community]

      expect(dump_keys.all? { |s| dump.key?(s) }).to eq(true)
      expect(community_name).to eq('learning_registry')
    end

    it 'rejects the dump if the transaction has not been persisted' do
      expect do
        transaction = build(:envelope_transaction)

        transaction.dump
      end.to raise_error(MR::TransactionNotPersistedError)
    end
  end

  describe '#build_from_dumped_representation' do
    let(:base64_transaction) do
      envelope = attributes_for(:envelope, :with_id)
                 .except(:id, :envelope_community_id)
                 .merge(envelope_community: 'credential_registry')
      Base64.urlsafe_encode64({ status: 'created',
                                date: Time.current.to_s,
                                envelope: envelope }.to_json)
    end

    it 'restores an envelope instance from a Base64 encoded representation' do
      transaction = EnvelopeTransaction.new

      transaction.build_from_dumped_representation(base64_transaction)
      envelope = transaction.envelope

      expect(transaction).to be_created
      expect(envelope.envelope_id).to eq('ac0c5f52-68b8-4438-bf34-6a63b1b95b56')
      expect(envelope.envelope_community.name).to eq('credential_registry')
    end
  end
end
