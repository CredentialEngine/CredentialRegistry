require 'argo_workflows_api_client'
require 'base64'
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
    workflow_service_api.workflow_service_get_workflow(
      namespace,
      name,
      return_type: 'Object'
    )
  end

  def submit_workflow(template_name:, parameters:, generate_name:)
    workflow_service_api.workflow_service_submit_workflow(
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
      configure_auth(config)
      config.timeout = ENV.fetch('ARGO_WORKFLOWS_TIMEOUT_SECONDS', 30).to_i

      # The in-cluster Argo endpoint uses a self-signed certificate.
      config.verify_ssl = false
      config.verify_ssl_host = false
    end
  end

  def workflow_service_api
    @workflow_service_api
  end

  def configure_auth(config)
    if env_present?('ARGO_WORKFLOWS_USERNAME', 'ARGO_WORKFLOWS_PASSWORD')
      config.api_key['Authorization'] = basic_auth_token
      config.api_key_prefix['Authorization'] = 'Basic'
    else
      config.api_key['Authorization'] = ENV.fetch('ARGO_WORKFLOWS_TOKEN')
      config.api_key_prefix['Authorization'] = 'Bearer'
    end
  end

  def env_present?(*keys)
    keys.all? { |key| ENV.fetch(key, nil).to_s != '' }
  end

  def basic_auth_token
    Base64.strict_encode64("#{ENV.fetch('ARGO_WORKFLOWS_USERNAME')}:#{ENV.fetch('ARGO_WORKFLOWS_PASSWORD')}")
  end
end
