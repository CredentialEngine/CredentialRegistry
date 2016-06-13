require 'generate_envelope_dump'
require 'envelope_transaction'

describe GenerateEnvelopeDump, type: :service do
  describe '#run' do
    let(:today) do
      Time.current.utc.to_date
    end

    let(:generate_envelope_dump) do
      GenerateEnvelopeDump.new(today)
    end

    before(:example) do
      envelope = create(:envelope)
      envelope.update_attributes(envelope_version: '1.0.0')
      envelope.update_attributes(deleted_at: Time.current)
    end

    after(:example) do
      File.unlink(generate_envelope_dump.dump_file)
    end

    it 'creates a dump file with the dumped envelopes' do
      generate_envelope_dump.run

      expect(File.exist?(generate_envelope_dump.dump_file)).to eq(true)
    end

    it 'contains dumped envelope transactions' do
      generate_envelope_dump.run

      transactions = extract_dump_transactions(generate_envelope_dump.dump_file)

      expect(transactions.size).to eq(3)
      expect(transactions.last['status']).to eq('deleted')
    end

    it 'stores a new dump in the database' do
      expect do
        generate_envelope_dump.run
      end.to change { EnvelopeDump.count }.by(1)
    end

    context 'dump already exists in the database' do
      it 'rejects the dump creation' do
        generate_envelope_dump.run

        expect do
          generate_envelope_dump.run
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
