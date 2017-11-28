require 'internet_archive'

# Generates a Gzip compresed dump file containing the dumped envelope
# transactions
class GenerateEnvelopeDump
  attr_reader :date, :community, :provider, :file_name

  DUMPS_PATH = MR.root_path.join('tmp', 'dumps')

  def initialize(date,
                 community,
                 provider = InternetArchive.new(community.backup_item))
    @date = date
    @community = community
    @provider = provider
    @file_name = "dump-#{date}.txt.gz"
    return if File.directory?(DUMPS_PATH)

    FileUtils.mkdir_p(DUMPS_PATH)
  end

  def run
    write_dump_to_file
  end

  def dump_file
    DUMPS_PATH.join(file_name)
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
