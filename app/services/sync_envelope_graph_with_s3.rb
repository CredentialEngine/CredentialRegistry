# Uploads or deletes an envelope graph from the S3 bucket
class SyncEnvelopeGraphWithS3
  attr_reader :envelope

  delegate :envelope_community, :envelope_ceterms_ctid, to: :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  class << self
    def upload(envelope)
      new(envelope).upload
    end

    def remove(envelope)
      new(envelope).remove
    end
  end

  def upload
    return unless s3_bucket_name

    s3_object.put(
      body: envelope.processed_resource.to_json,
      content_type: 'application/json'
    )

    envelope.update_column(:s3_url, s3_object.public_url)
  end

  def remove
    return unless s3_bucket_name

    s3_object.delete
  end

  def s3_bucket
    @s3_bucket ||= s3_resource.bucket(s3_bucket_name)
  end

  def s3_bucket_name
    ENV['ENVELOPE_GRAPHS_BUCKET'].presence
  end

  def s3_key
    "#{envelope_community.name}/#{envelope_ceterms_ctid}.json"
  end

  def s3_object
    @s3_object ||= s3_bucket.object(s3_key)
  end

  def s3_resource
    @s3_resource ||= Aws::S3::Resource.new(region: ENV['AWS_REGION'].presence)
  end
end
