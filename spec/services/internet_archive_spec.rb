require 'internet_archive'
require 'envelope_dump'

describe InternetArchive, type: :service do
  let(:internet_archive) { InternetArchive.new }
  let(:dump_file) { 'spec/support/fixtures/transactions-dump.txt.gz' }

  describe '#location' do
    it 'returns the proper location given a file name' do
      allow(internet_archive).to receive(:current_item) { 'test-item' }
      location = internet_archive.location(dump_file)

      expect(location).to eq('http://s3.us.archive.org/test-item/transactions-dump.txt.gz')
    end
  end

  context 'with remote server access' do
    before(:example) do
      @upload_response = internet_archive.upload(dump_file)
    end

    describe '#upload', :vcr do
      it 'uploads a regular dump file' do
        expect(@upload_response.code).to eq(200)
        expect(@upload_response.body).to eq('')
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
        dump = build(:envelope_dump,
                     location: internet_archive.location(dump_file))

        expect(File.exist?(internet_archive.retrieve(dump))).to eq(true)
      end
    end
  end
end
