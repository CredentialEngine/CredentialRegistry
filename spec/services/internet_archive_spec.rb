require 'internet_archive'
require 'envelope_dump'

describe InternetArchive, type: :service do
  let(:internet_archive) { InternetArchive.new }
  let(:dump_file) { 'spec/support/fixtures/transactions-dump.txt' }

  describe '#location' do
    it 'returns the proper location given a file name' do
      allow(internet_archive).to receive(:current_item) { 'test-item' }
      location = internet_archive.location(dump_file)

      expect(location).to eq('https://s3.us.archive.org/test-item/transactions-dump.txt')
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
      it 'downloads a dump file from the remote servers' do
        dump = build(:envelope_dump,
                     location: internet_archive.location(dump_file))
        dump_file = internet_archive.retrieve(dump)

        expect(dump_file).to be_a(Enumerator)
        expect_base64(dump_file.next.strip)
      end
    end
  end
end
