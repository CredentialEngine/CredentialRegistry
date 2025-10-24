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
    @client ||= Elasticsearch::Client.new(host: elasticsearch_host)
  end

  def elasticsearch_host
    ENV['ELASTICSEARCH_HOST'].presence
  end

  def index
    return unless elasticsearch_host

    client.index(
      body: envelope.processed_resource.to_json,
      id: envelope_ceterms_ctid,
      index: envelope_community.name
    )
  end

  def delete
    return unless elasticsearch_host

    client.delete(id: envelope_ceterms_ctid, index: envelope_community.name)
  rescue Elastic::Transport::Transport::Errors::NotFound
    nil
  end
end
