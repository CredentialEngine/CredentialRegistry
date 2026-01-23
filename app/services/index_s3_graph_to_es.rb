# Indexes a JSON-LD graph from S3 directly to Elasticsearch
# Does not require database access - S3 is the source of truth
class IndexS3GraphToEs
  attr_reader :s3_key, :community_name, :ctid

  def initialize(s3_key)
    @s3_key = s3_key
    parse_s3_key
  end

  class << self
    def call(s3_key)
      new(s3_key).call
    end
  end

  def call
    return unless elasticsearch_address

    client.index(
      body: graph_json,
      id: ctid,
      index: community_name
    )
  rescue Elastic::Transport::Transport::Errors::BadRequest => e
    raise e unless e.message.include?('Limit of total fields')

    increase_total_fields_limit
    retry
  end

  private

  def parse_s3_key
    # S3 key format: {community_name}/{ctid}.json
    parts = s3_key.split('/')
    @community_name = parts[0..-2].join('/')
    @ctid = parts.last.sub(/\.json\z/i, '')
  end

  def graph_content
    @graph_content ||= s3_object.get.body.read
  end

  def graph_json
    @graph_json ||= JSON.parse(graph_content).to_json
  end

  def client
    @client ||= Elasticsearch::Client.new(host: elasticsearch_address)
  end

  def elasticsearch_address
    ENV['ELASTICSEARCH_ADDRESS'].presence
  end

  def s3_bucket
    @s3_bucket ||= s3_resource.bucket(s3_bucket_name)
  end

  def s3_bucket_name
    ENV['ENVELOPE_GRAPHS_BUCKET'].presence
  end

  def s3_object
    @s3_object ||= s3_bucket.object(s3_key)
  end

  def s3_resource
    @s3_resource ||= Aws::S3::Resource.new(region: ENV['AWS_REGION'].presence)
  end

  def increase_total_fields_limit
    settings = client.indices.get_settings(index: community_name)

    current_limit = settings
                    .dig(community_name, 'settings', 'index', 'mapping', 'total_fields', 'limit')
                    .to_i

    client.indices.put_settings(
      body: { 'index.mapping.total_fields.limit' => current_limit * 2 },
      index: community_name
    )
  end
end
