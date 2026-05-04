require 'argo_workflows_client'

class SubmitEnvelopeDownloadWorkflow
  TEMPLATE_NAME = 's3-graphs-zip'.freeze

  def self.call(envelope_download:)
    new(envelope_download).call
  end

  attr_reader :envelope_download

  def initialize(envelope_download)
    @envelope_download = envelope_download
  end

  def call
    envelope_download.with_lock do
      return envelope_download if workflow_already_started?

      workflow = client.submit_workflow(
        template_name: TEMPLATE_NAME,
        generate_name: "#{community_name.tr('_', '-')}-download-",
        parameters:
      )
      workflow_name = workflow.dig(:metadata, :name)
      raise 'Argo workflow submission did not return a workflow name' if workflow_name.blank?

      envelope_download.update!(
        argo_workflow_name: workflow_name,
        argo_workflow_namespace: client.namespace,
        finished_at: nil,
        internal_error_backtrace: [],
        internal_error_message: nil,
        started_at: Time.current,
        status: :in_progress,
        zip_files: [],
        url: nil
      )
    end
  rescue StandardError => e
    envelope_download.update!(
      argo_workflow_name: nil,
      argo_workflow_namespace: nil,
      finished_at: Time.current,
      internal_error_backtrace: Array(e.backtrace),
      internal_error_message: e.message,
      status: :finished,
      zip_files: [],
      url: nil
    )
    raise
  end

  private

  def client
    @client ||= ArgoWorkflowsClient.new
  end

  def community_name
    envelope_download.envelope_community.name
  end

  def destination_prefix
    "#{community_name}/downloads/#{envelope_download.id}"
  end

  def parameters
    {
      'batch-size' => ENV.fetch('ARGO_WORKFLOWS_BATCH_SIZE', '25000'),
      'aws-region' => ENV.fetch('AWS_REGION'),
      'destination-bucket' => ENV.fetch('ENVELOPE_DOWNLOADS_BUCKET'),
      'destination-prefix' => destination_prefix,
      'environment' => MR.env,
      'max-uncompressed-zip-size-bytes' => ENV.fetch(
        'ARGO_WORKFLOWS_MAX_UNCOMPRESSED_ZIP_SIZE_BYTES',
        (200 * 1024 * 1024).to_s
      ),
      'max-workers' => ENV.fetch('ARGO_WORKFLOWS_MAX_WORKERS', '4'),
      'source-bucket' => ENV.fetch('ENVELOPE_GRAPHS_BUCKET'),
      'source-prefix' => community_name,
      'task-image' => ENV.fetch('ARGO_WORKFLOWS_TASK_IMAGE')
    }
  end

  def workflow_already_started?
    envelope_download.in_progress? && envelope_download.argo_workflow_name.present?
  end
end
