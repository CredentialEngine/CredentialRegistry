# Adds or deletes an envelope graph from the Elasticsearch index
class SyncEnvelopeGraphWithEs
  attr_reader :envelope

  delegate :envelope_community, :envelope_ceterms_ctid, to: :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  class << self
    def index(envelope)
      new(envelope).index
    end

    def delete(envelope)
      new(envelope).delete
    end
  end

  def client
    @client ||= Elasticsearch::Client.new(host: elasticsearch_address)
  end

  def elasticsearch_address
  ENV['ELASTICSEARCH_ADDRESS'].presence
  end

  def index
    return unless elasticsearch_address

    client.index(
      body: envelope.processed_resource.to_json,
      id: envelope_ceterms_ctid,
      index: envelope_community.name
    )

    envelope.touch(:indexed_with_es_at)
  end

  def delete
    return unless elasticsearch_address

    client.delete(id: envelope_ceterms_ctid, index: envelope_community.name)
  rescue Elastic::Transport::Transport::Errors::NotFound
    nil
  end
end
