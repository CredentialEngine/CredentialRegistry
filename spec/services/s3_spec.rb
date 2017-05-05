require 's3'

describe S3, type: :service do
  let(:s3) { S3.new('learning-registry-test') }
  let(:dump_file) { 'spec/support/fixtures/transactions-dump.txt.gz' }

  describe '#initialize' do
    it 'raises an error if item is missing' do
      expect do
        S3.new(' ')
      end.to raise_error MR::BackupItemMissingError
    end
  end

  describe '#location' do
    it 'returns the proper location given a file name' do
      expect(s3.location(dump_file)).to eq('transactions-dump.txt.gz')
    end
  end

  context 'with remote server access' do
    let!(:upload) { @upload_response = s3.upload(dump_file) }

    describe '#upload', :vcr do
      it 'uploads a regular dump file' do
        expect(upload).to be true
      end
    end

    describe '#delete', :vcr do
      it 'deletes a previously uploaded dump file' do
        s3.delete(dump_file)

        expect do
          s3.retrieve(dump_file)
        end.to raise_error(Aws::S3::Errors::NotFound)
      end
    end

    describe '#retrieve', :vcr do
      it 'downloads the remote dump and stores it in a temp file' do
        location = s3.location(dump_file)

        expect(File.exist?(s3.retrieve(location))).to eq(true)
      end
    end
  end
end
