require 'envelope_dump'
require 'internet_archive'

# Generates a dump file containing the envelope transactions in JSON format
class GenerateEnvelopeDump
  DUMPS_PATH = 'tmp/dumps'.freeze

  attr_reader :date, :provider, :file_name

  def initialize(date, provider)
    @date = date
    @provider = provider
    @file_name = "dump-#{date}.json"
    FileUtils.mkdir_p(DUMPS_PATH) unless File.directory?(DUMPS_PATH)
  end

  def run
    write_dump_to_file
    create_dump_record
  end

  private

  def create_dump_record
    EnvelopeDump.create(provider: provider.name,
                        item: provider.current_item,
                        location: provider.location(file_name),
                        dumped_at: date)
  end

  def write_dump_to_file
    File.write("#{DUMPS_PATH}/#{file_name}", dump_contents.to_json)
  end

  def dump_contents
    dump_contents = []
    transactions.each do |transaction|
      dump_contents << transaction.dump
    end
  end

  def transactions
    EnvelopeTransaction.in_date(date)
  end
end
