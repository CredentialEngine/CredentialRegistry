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
      each_envelope_in_dump(dump) do |envelope_attrs|
        envelope = build_envelope(envelope_attrs)
        envelope.save!
      end
    end
  end

  private

  #
  # Downloads the compressed dump file, uncompresses it and finally yields every
  # envelope belonging to a Base64 encoded transaction
  #
  def each_envelope_in_dump(dump)
    Zlib::GzipReader.open(provider.retrieve(dump)) do |gzip_file|
      gzip_file.each_line do |line|
        transaction = JSON.parse(Base64.urlsafe_decode64(line.strip))
        yield(transaction['envelope'])
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

  def build_envelope(attrs)
    community_name = attrs.delete('envelope_community')
    community = EnvelopeCommunity.find_or_create_by!(name: community_name)

    envelope = Envelope.find_or_initialize_by(envelope_id: attrs['envelope_id'])
    envelope.assign_attributes(attrs.merge(envelope_community: community))

    envelope
  end
end
