require 'generate_envelope_dump'
require 'envelope_transaction'

RSpec.describe GenerateEnvelopeDump, type: :service do
  describe '#run' do
    let(:today) do
      Time.current.utc.to_date
    end

    let(:generate_envelope_dump) do
      described_class.new(today, build(:envelope_community))
    end

    before do
      envelope = create(:envelope)
      envelope.update(envelope_version: '1.0.0')
      envelope.update(deleted_at: Time.current)
      create(:envelope, :from_cer)
    end

    after do
      File.unlink(generate_envelope_dump.dump_file)
    end

    it 'creates a dump file with the dumped envelopes' do
      generate_envelope_dump.run

      expect(File.exist?(generate_envelope_dump.dump_file)).to be(true)
    end

    it 'contains dumped envelope transactions' do
      generate_envelope_dump.run

      transactions = extract_dump_transactions(generate_envelope_dump.dump_file)
      community_name = transactions.last.dig('envelope', 'envelope_community')

      expect(transactions.size).to eq(3)
      expect(transactions.last['status']).to eq('deleted')
      expect(community_name).to eq('learning_registry')
    end
  end
end
