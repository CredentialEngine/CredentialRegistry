require 'envelope_dump'
require 'internet_archive'

# Generates a dump file containing the envelope transactions in JSON format
class GenerateEnvelopeDump
  attr_reader :date, :file_name

  def initialize(date)
    @date = date
    @file_name = "dump-#{date}.json"
  end

  def run
    write_dump_to_file
    create_dump_record
  end

  private

  def create_dump_record
    EnvelopeDump.create(item: InternetArchive.current_item,
                        location: InternetArchive.location(file_name),
                        dumped_at: date)
  end

  def write_dump_to_file
    File.write("tmp/dumps/#{file_name}", dump_contents.to_json)
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
