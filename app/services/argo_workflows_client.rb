require 'argo_workflows_api_client'
require 'uri'

class ArgoWorkflowsClient
  attr_reader :namespace

  def initialize(configuration: build_configuration)
    @namespace = ENV.fetch('ARGO_WORKFLOWS_NAMESPACE')
    @workflow_service_api = ArgoWorkflowsApiClient::WorkflowServiceApi.new(
      ArgoWorkflowsApiClient::ApiClient.new(configuration)
    )
  end

  def get_workflow(name:)
    @workflow_service_api.workflow_service_get_workflow(
      namespace,
      name,
      return_type: 'Object'
    )
  end

  def submit_workflow(template_name:, parameters:, generate_name:)
    @workflow_service_api.workflow_service_submit_workflow(
      {
        namespace:,
        resourceKind: 'WorkflowTemplate',
        resourceName: template_name,
        submitOptions: {
          generateName: generate_name,
          parameters: parameters.map { |key, value| "#{key}=#{value}" }
        }
      },
      namespace,
      return_type: 'Object'
    )
  end

  private

  def build_configuration
    base_uri = URI.parse(ENV.fetch('ARGO_WORKFLOWS_BASE_URL'))

    ArgoWorkflowsApiClient::Configuration.new.tap do |config|
      config.scheme = base_uri.scheme
      config.host = [base_uri.host, base_uri.port].compact.join(':')
      config.base_path = base_uri.path
      config.api_key['Authorization'] = ENV.fetch('ARGO_WORKFLOWS_TOKEN', nil)
      config.api_key_prefix['Authorization'] = 'Bearer'
      config.timeout = ENV.fetch('ARGO_WORKFLOWS_TIMEOUT_SECONDS', 30).to_i

      config.verify_ssl = ENV.fetch('ARGO_WORKFLOWS_VERIFY_SSL', 'true') != 'false'
      config.verify_ssl_host = ENV.fetch('ARGO_WORKFLOWS_VERIFY_SSL', 'true') != 'false'
    end
  end
end
