require 'internet_archive'
require 's3'

# Restores the envelopes in the database by reading the transaction dump file
# downloaded from the given provider
class RestoreEnvelopeDumps
  attr_reader :from_date, :community, :provider

  def initialize(from_date,
                 community,
                 provider = InternetArchive.new(community.backup_item))
    @from_date = from_date
    @community = community
    @provider = provider
  end

  def run
    dump_locations.each do |dump_location|
      each_envelope_in_dump(dump_location, &:save!)
    end
  end

  private

  #
  # Downloads the compressed dump file, uncompresses it and reads the file line
  # by line, building and yielding the associated envelope in each iteration
  #
  def each_envelope_in_dump(dump_location)
    Zlib::GzipReader.open(provider.retrieve(dump_location)) do |gzip_file|
      gzip_file.each_line do |line|
        transaction = EnvelopeTransaction.new
        transaction.build_from_dumped_representation(line)
        yield(transaction.envelope)
      end
      gzip_file.close
    end
  rescue OpenURI::HTTPError
    MR.logger.warn "Can not download #{dump_location}. Omitting..."
  end

  def dump_locations
    dump_locations = []
    (from_date..Date.current).each do |dump_date|
      dump_locations << provider.location("dump-#{dump_date}.txt.gz")
    end
    dump_locations
  end
end
