require 'internet_archive'
require 's3'

# Generates a Gzip compresed dump file containing the dumped envelope
# transactions
class GenerateEnvelopeDump
  attr_reader :date, :community, :provider, :file_name

  def initialize(date,
                 community,
                 provider = InternetArchive.new(community.backup_item))
    @date = date
    @community = community
    @provider = provider
    @file_name = "dump-#{date}.txt.gz"
    return if File.directory?(MetadataRegistry.dumps_path)

    FileUtils.mkdir_p(MetadataRegistry.dumps_path)
  end

  def run
    write_dump_to_file
  end

  def dump_file
    "#{MetadataRegistry.dumps_path}/#{file_name}"
  end

  private

  def write_dump_to_file
    Zlib::GzipWriter.open(dump_file) do |gzip_file|
      transactions.each { |transaction| gzip_file.puts(transaction.dump) }
      gzip_file.close
    end
  end

  def transactions
    EnvelopeTransaction.in_community(community.name).in_date(date)
  end
end
