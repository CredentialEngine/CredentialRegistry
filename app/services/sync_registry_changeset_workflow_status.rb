require 'argo_workflows_client'

class SyncRegistryChangesetWorkflowStatus
  SUCCESS_PHASE = 'Succeeded'.freeze
  FAILURE_PHASES = %w[Error Failed].freeze
  RUNNING_PHASES = %w[Pending Running].freeze

  def self.call(sync:)
    new(sync).call
  end

  attr_reader :sync

  def initialize(sync)
    @sync = sync
  end

  def call
    return sync unless sync.syncing?
    return sync if workflows.empty?

    statuses = workflows.map { |workflow| workflow_status(workflow) }
    failure = statuses.find { |status| status[:failed] }

    if failure
      sync.mark_sync_error!(StandardError.new(failure[:message]))
      sync.clear_argo_workflows!
      sync.clear_syncing!
    elsif statuses.all? { |status| status[:succeeded] }
      sync.mark_synced_through!(
        version_id: sync.last_activity_version_id,
        resource_event_id: sync.last_activity_resource_event_id
      )
      sync.clear_argo_workflows!
      sync.clear_syncing!
    end

    sync
  end

  private

  def workflows
    @workflows ||= Array(sync.argo_workflows).select { |workflow| workflow['name'].present? }
  end

  def client
    @client ||= ArgoWorkflowsClient.new
  end

  def workflow_status(workflow)
    response = client.get_workflow(name: workflow.fetch('name'))
    status = response.fetch(:status, {})
    phase = status[:phase]

    if phase == SUCCESS_PHASE
      { succeeded: true }
    elsif FAILURE_PHASES.include?(phase)
      { failed: true, message: workflow_failure_message(workflow, status) }
    elsif RUNNING_PHASES.include?(phase) || phase.blank?
      { running: true }
    else
      { running: true }
    end
  rescue ArgoWorkflowsApiClient::ApiError => e
    if workflow_not_found?(e)
      { failed: true, message: "Argo workflow #{workflow['name']} not found: #{e.message}" }
    else
      MR.logger.warn("Unable to sync Argo workflow #{workflow['name']}: #{e.message}")
      { running: true }
    end
  end

  def workflow_failure_message(workflow, status)
    status[:message].presence || "Argo workflow #{workflow['name']} #{status[:phase].to_s.downcase}"
  end

  def workflow_not_found?(error)
    error.respond_to?(:code) && error.code.to_i == 404
  end
end
