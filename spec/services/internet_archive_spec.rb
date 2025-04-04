require 'internet_archive'

RSpec.describe InternetArchive, type: :service do
  let(:internet_archive) { described_class.new('learning-registry-test') }
  let(:dump_file) { 'spec/support/fixtures/transactions-dump.txt.gz' }

  describe '#initialize' do
    it 'raises an error if item is missing' do
      expect do
        described_class.new(' ')
      end.to raise_error MR::BackupItemMissingError
    end
  end

  describe '#location' do
    it 'returns the proper location given a file name' do
      allow(internet_archive).to receive(:item).and_return('test-item')
      location = internet_archive.location(dump_file)

      expect(location).to eq('http://s3.us.archive.org/test-item/transactions-dump.txt.gz')
    end
  end

  context 'with remote server access' do
    before do
      @upload_response = internet_archive.upload(dump_file)
    end

    describe '#upload', :vcr do
      it 'uploads a regular dump file' do
        expect(@upload_response.code).to eq(200) # rubocop:todo RSpec/InstanceVariable
        expect(@upload_response.body).to eq('') # rubocop:todo RSpec/InstanceVariable
      end
    end

    describe '#delete', :vcr do
      it 'deletes a previously uploaded dump file' do
        response = internet_archive.delete(dump_file)

        expect(response.code).to eq(204)
        expect(response.body).to eq('')
      end
    end

    describe '#retrieve', :vcr do
      it 'downloads the remote dump and stores it in a temp file' do
        location = internet_archive.location(dump_file)

        expect(File.exist?(internet_archive.retrieve(location))).to be(true)
      end
    end
  end
end
