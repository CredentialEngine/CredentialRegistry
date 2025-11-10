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
      index: index_name
    )

    envelope.touch(:indexed_with_es_at)
  rescue Elastic::Transport::Transport::Errors::BadRequest => e
    raise e unless e.message =~ /Limit of total fields/

    increase_total_fields_limit
    retry
  end

  def delete
    return unless elasticsearch_address

    client.delete(id: envelope_ceterms_ctid, index: index_name)
  rescue Elastic::Transport::Transport::Errors::NotFound
    nil
  end

  def increase_total_fields_limit
    settings = client.indices.get_settings(index: index_name)

    current_limit = settings
      .dig(index_name, 'settings', 'index', 'mapping', 'total_fields', 'limit')
      .to_i

    client.indices.put_settings(
      body: { "index.mapping.total_fields.limit" => current_limit * 2 },
      index: index_name
    )
  end

  def index_name
    envelope_community.name
  end
end
