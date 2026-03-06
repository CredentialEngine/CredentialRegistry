require 'argo_workflows_client'
require 'aws-sdk-s3'
require 'json'

class SyncEnvelopeDownloadWorkflowStatus
  SUCCESS_PHASE = 'Succeeded'.freeze
  FAILURE_PHASES = %w[Error Failed].freeze
  RUNNING_PHASE = 'Running'.freeze

  def self.call(envelope_download:)
    new(envelope_download).call
  end

  attr_reader :envelope_download

  def initialize(envelope_download)
    @envelope_download = envelope_download
  end

  def call
    return envelope_download if envelope_download.argo_workflow_name.blank?
    return envelope_download if envelope_download.finished? && envelope_download.zip_files.present?

    workflow = client.get_workflow(name: envelope_download.argo_workflow_name)
    status = workflow.fetch(:status, {})
    phase = status[:phase]

    if phase == SUCCESS_PHASE
      mark_success!(status)
    elsif FAILURE_PHASES.include?(phase)
      mark_failure!(status)
    elsif phase == RUNNING_PHASE
      mark_in_progress!(status)
    end

    envelope_download
  rescue ArgoWorkflowsApiClient::ApiError => e
    MR.logger.warn("Unable to sync Argo workflow #{envelope_download.argo_workflow_name}: #{e.message}")
    envelope_download
  end

  private

  def client
    @client ||= ArgoWorkflowsClient.new
  end

  def community_name
    envelope_download.envelope_community.name
  end

  def destination_bucket
    ENV.fetch('ENVELOPE_DOWNLOADS_BUCKET')
  end

  def mark_failure!(status)
    envelope_download.update!(
      finished_at: parse_time(status[:finishedAt]) || Time.current,
      internal_error_backtrace: [],
      internal_error_message: status[:message] || "Argo workflow #{status[:phase].to_s.downcase}",
      status: :finished,
      zip_files: [],
      url: nil
    )
  end

  def mark_in_progress!(status)
    envelope_download.update!(
      started_at: parse_time(status[:startedAt]) || envelope_download.started_at || Time.current,
      status: :in_progress
    )
  end

  def mark_success!(status)
    manifest = output_manifest(status)
    zip_files = manifest.fetch('zip_files', [])

    if zip_files.present?
      envelope_download.update!(
        finished_at: parse_time(status[:finishedAt]) || Time.current,
        internal_error_backtrace: [],
        internal_error_message: nil,
        status: :finished,
        url: public_url_for(zip_files.first),
        zip_files:
      )
    else
      envelope_download.update!(
        finished_at: parse_time(status[:finishedAt]) || Time.current,
        internal_error_backtrace: [],
        internal_error_message: 'Argo workflow succeeded but did not return any ZIP files',
        status: :finished,
        zip_files: [],
        url: nil
      )
    end
  end

  def parse_time(value)
    Time.zone.parse(value) if value.present?
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: ENV.fetch('AWS_REGION'))
  end

  def output_manifest(status)
    parameter = status.fetch(:outputs, {})
                      .fetch(:parameters, [])
                      .find { |item| item[:name] == 'zip-manifest' }
    return {} unless parameter

    JSON.parse(parameter.fetch(:value))
  end

  def public_url_for(key)
    s3_client.head_object(bucket: destination_bucket, key:)
    Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
                     .bucket(destination_bucket)
                     .object(key)
                     .public_url
  rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
    nil
  end
end
