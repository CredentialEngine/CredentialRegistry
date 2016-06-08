require 'envelope_dump'
require 'internet_archive'

# Generates a dump file containing the envelope transactions in JSON format
class RestoreEnvelopeDumps
  attr_reader :from_date, :provider

  def initialize(from_date, provider = InternetArchive.new)
    @from_date = from_date
    @provider = provider
  end

  def run
    dumps.each do |dump|
      transactions = download_dump(dump)
      every_transaction(transactions) do |envelope_attrs|
        envelope = build_envelope(envelope_attrs)
        envelope.save!
      end
    end
  end

  private

  def download_dump(dump)
    provider.retrieve(dump)
  rescue RestClient::ResourceNotFound
    LR.logger.warn "Can not download #{dump.location}. Omitting..."
    [].to_enum
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
                     location: provider.location("dump-#{dump_date}.json"),
                     dumped_at: dump_date)
  end

  def every_transaction(transactions)
    transactions.each do |b64_transaction|
      transaction = JSON.parse(Base64.urlsafe_decode64(b64_transaction.strip))
      yield(transaction['envelope'])
    end
  end

  def build_envelope(attrs)
    community_name = attrs.delete('envelope_community')
    community = EnvelopeCommunity.find_or_create_by!(name: community_name)

    envelope = Envelope.find_or_initialize_by(envelope_id: attrs['envelope_id'])
    envelope.assign_attributes(attrs.merge(envelope_community: community))

    envelope
  end
end
