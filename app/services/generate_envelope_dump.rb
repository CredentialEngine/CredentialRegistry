require 'envelope_dump'
require 'internet_archive'

# Generates a dump file containing the envelope transactions in JSON format
class GenerateEnvelopeDump
  attr_reader :date, :provider, :file_name

  def initialize(date, provider = InternetArchive.new)
    @date = date
    @provider = provider
    @file_name = "dump-#{date}.json"
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

  def create_dump_record
    EnvelopeDump.create!(provider: provider.name,
                         item: provider.current_item,
                         location: provider.location(file_name),
                         dumped_at: date)
  end

  def write_dump_to_file
    File.write(dump_file, dump_contents.to_json)
  end

  def dump_contents
    dump_contents = []
    transactions.each do |transaction|
      dump_contents << transaction.dump
    end
    dump_contents
  end

  def transactions
    EnvelopeTransaction.in_date(date)
  end
end
