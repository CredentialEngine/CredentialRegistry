require 'generate_envelope_dump'
require 'envelope_transaction'

describe GenerateEnvelopeDump, type: :service do
  FILE_NAME = "tmp/dumps/dump-#{Date.today}.json".freeze
  let!(:transactions) do
    [create(:envelope_transaction, status: :updated),
     create(:envelope_transaction, status: :deleted)]
  end
  let(:generate_envelope_dump) { GenerateEnvelopeDump.new(Date.today) }

  after(:context) do
    File.unlink(FILE_NAME)
  end

  it 'creates a dump file with the dumped envelopes' do
    generate_envelope_dump.run

    expect(File.exist?(FILE_NAME)).to eq(true)
  end

  it 'contains dumped envelope transactions' do
    dump = JSON.parse(File.read(FILE_NAME))

    generate_envelope_dump.run

    expect(dump.size).to eq(2)
    expect(dump.last['status']).to eq('deleted')
  end

  it 'stores a new dump in the database' do
    expect do
      generate_envelope_dump.run
    end.to change { EnvelopeDump.count }.by(1)
  end
end
