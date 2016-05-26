require 'internet_archive'
require 'envelope_dump'

describe InternetArchive, type: :service do
  let(:internet_archive) { InternetArchive.new }
  let(:dump_file) { 'spec/support/fixtures/transactions-dump.json' }

  describe '#location' do
    it 'returns the proper location given a file name' do
      allow(internet_archive).to receive(:current_item) { 'test-item' }
      location = internet_archive.location(dump_file)

      expect(location).to eq('https://s3.us.archive.org/test-item/transactions-dump.json')
    end
  end

  describe '#upload', :vcr do
    it 'uploads a regular dump file' do
      response = internet_archive.upload(dump_file)

      expect(response.code).to eq(200)
      expect(response.body).to eq('')
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
      dump = build(:envelope_dump)
      response = internet_archive.retrieve(dump)

      expect(response.code).to eq(200)
      expect(response.body).not_to eq('')
    end
  end
end
