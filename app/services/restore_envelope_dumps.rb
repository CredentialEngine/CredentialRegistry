require 'envelope_dump'
require 'internet_archive'

# Restores the envelopes in the database by reading the transaction dump file
# downloaded from the given provider
class RestoreEnvelopeDumps
  attr_reader :from_date, :provider

  def initialize(from_date, provider = InternetArchive.new)
    @from_date = from_date
    @provider = provider
  end

  def run
    dumps.each do |dump|
      each_envelope_in_dump(dump, &:save!)
    end
  end

  private

  #
  # Downloads the compressed dump file, uncompresses it and reads the file line
  # by line, building and yielding the associated envelope in each iteration
  #
  def each_envelope_in_dump(dump)
    Zlib::GzipReader.open(provider.retrieve(dump)) do |gzip_file|
      gzip_file.each_line do |line|
        transaction = EnvelopeTransaction.new
        transaction.build_from_dumped_representation(line)
        yield(transaction.envelope)
      end
      gzip_file.close
    end
  rescue OpenURI::HTTPError
    LR.logger.warn "Can not download #{dump.location}. Omitting..."
  end

  def dumps
    dumps = []
    (from_date..Date.current).each do |dump_date|
      dumps << build_dump(provider, dump_date)
    end
    dumps
  end

  def build_dump(provider, dump_date)
    EnvelopeDump.new(provider: provider.name,
                     item: provider.current_item,
                     location: provider.location("dump-#{dump_date}.txt.gz"),
                     dumped_at: dump_date)
  end
end
