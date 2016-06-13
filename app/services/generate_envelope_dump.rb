require 'envelope_dump'
require 'internet_archive'

# Generates a Gzip compresed dump file containing the dumped envelope
# transactions
class GenerateEnvelopeDump
  attr_reader :date, :provider, :file_name

  def initialize(date, provider = InternetArchive.new)
    @date = date
    @provider = provider
    @file_name = "dump-#{date}.txt.gz"
    unless File.directory?(LearningRegistry.dumps_path)
      FileUtils.mkdir_p(LearningRegistry.dumps_path)
    end
  end

  def run
    write_dump_to_file
    create_dump_record
  end

  def dump_file
    "#{LearningRegistry.dumps_path}/#{file_name}"
  end

  private

  def write_dump_to_file
    Zlib::GzipWriter.open(dump_file) do |gzip_file|
      transactions.each { |transaction| gzip_file.puts(transaction.dump) }
      gzip_file.close
    end
  end

  def transactions
    EnvelopeTransaction.in_date(date)
  end

  def create_dump_record
    EnvelopeDump.create!(provider: provider.name,
                         item: provider.current_item,
                         location: provider.location(file_name),
                         dumped_at: date)
  end
end
