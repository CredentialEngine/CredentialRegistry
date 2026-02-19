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
    trigger_validate_graph_workflow
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

  def trigger_validate_graph_workflow
    argo_token = ENV['ARGO_TOKEN'].presence
    argo_namespace = ENV['ARGO_NAMESPACE'].presence || 'credreg-staging'
    dest_bucket = ENV['ARGO_RESOURCE_BUCKET'].presence || 'cer-resources-prod'
    return unless argo_token

    graph_s3_path = "s3://#{s3_bucket_name}/#{s3_key}"
    argo_url = "https://argo-server.#{argo_namespace}.svc.cluster.local:2746"

    HTTP.auth("Bearer #{argo_token}")
        .ssl_context(OpenSSL::SSL::SSLContext.new.tap { |ctx| ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE })
        .post(
          "#{argo_url}/api/v1/workflows/#{argo_namespace}/submit",
          json: {
            namespace: argo_namespace,
            resourceKind: 'WorkflowTemplate',
            resourceName: 'validate-graph-resources',
            submitOptions: {
              parameters: [
                "graph-s3-path=#{graph_s3_path}",
                "dest-bucket=#{dest_bucket}"
              ]
            }
          }
        )
  rescue StandardError => e
    MR.logger.error("Failed to trigger validate-graph-resources workflow: #{e.message}")
  end
end
