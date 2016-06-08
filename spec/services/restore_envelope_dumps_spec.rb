require 'restore_envelope_dumps'

describe RestoreEnvelopeDumps, type: :service do
  describe '#run' do
    let(:dump_name) { 'spec/support/fixtures/transactions-dump.txt' }
    let(:provider) { InternetArchive.new }
    let(:restore_envelope_dumps) do
      RestoreEnvelopeDumps.new(Date.current - 3, provider)
    end

    before(:example) do
      allow(provider).to receive(:retrieve) { File.foreach(dump_name) }
    end

    it 'restores all transactions from a dump file' do
      expect do
        restore_envelope_dumps.run
      end.to change { EnvelopeTransaction.count }.by(12)
    end

    it 'honors the type of transaction' do
      restore_envelope_dumps.run

      first, second, third = EnvelopeTransaction.limit(3)

      expect(first).to be_created
      expect(second).to be_updated
      expect(third).to be_deleted
    end
  end
end
