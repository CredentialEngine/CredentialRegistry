require 'argo_workflows_client'

class SubmitChangesetWorkflow
  TEMPLATE_NAME = 'apply-changeset'.freeze

  def self.call(envelope_community:, entity_type:, manifest_key:)
    new(envelope_community: envelope_community, entity_type: entity_type, manifest_key: manifest_key).call
  end

  attr_reader :envelope_community, :entity_type, :manifest_key

  def initialize(envelope_community:, entity_type:, manifest_key:)
    @envelope_community = envelope_community
    @entity_type = entity_type.to_s
    @manifest_key = manifest_key
  end

  def call
    workflow = client.submit_workflow(
      template_name: TEMPLATE_NAME,
      generate_name: "#{community_name.tr('_', '-')}-apply-changeset-#{entity_type}-",
      parameters: parameters
    )
    workflow_name = workflow.dig(:metadata, :name)
    raise 'Argo workflow submission did not return a workflow name' if workflow_name.blank?

    workflow[:namespace] ||= client.namespace
    workflow
  end

  private

  def client
    @client ||= ArgoWorkflowsClient.new
  end

  def community_name
    envelope_community.name
  end

  def task_image
    ENV.fetch('ARGO_WORKFLOWS_TASK_IMAGE')
  end

  def parameters
    optional_parameters.merge(
      'task-image' => task_image,
      'entity-type' => entity_type,
      'input-bucket' => source_bucket,
      'input-file-key' => manifest_key,
      'source-bucket' => source_bucket,
      'target-bucket' => target_bucket,
      'aws-region' => ENV.fetch('AWS_REGION')
    )
  end

  def optional_parameters
    {
      'elasticsearch-url' => ENV['ELASTICSEARCH_URL'],
      'elasticsearch-username' => ENV['ELASTICSEARCH_USERNAME'],
      'elasticsearch-password' => ENV['ELASTICSEARCH_PASSWORD'],
      'aws-s3-service-url' => ENV['AWS_S3_SERVICE_URL']
    }.compact
  end

  def source_bucket
    ENV.fetch('REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET') { ENV.fetch('ENVELOPE_GRAPHS_BUCKET') }
  end

  def target_bucket
    ENV.fetch('REGISTRY_CHANGESET_SYNC_TARGET_BUCKET') { ENV.fetch('ENVELOPE_GRAPHS_BUCKET') }
  end
end
