require 'argo_workflows_api_client'
require 'base64'
require 'kubernetes_service_account_token_requester'
require 'uri'

class ArgoWorkflowsClient
  attr_reader :namespace

  def initialize(configuration: nil)
    configuration ||= build_configuration
    @namespace = configuration.fetch(:namespace)
    @workflow_service_api = ArgoWorkflowsApiClient::WorkflowServiceApi.new(
      ArgoWorkflowsApiClient::ApiClient.new(configuration.fetch(:client_configuration))
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
    namespace = ENV.fetch('ARGO_WORKFLOWS_NAMESPACE')

    client_configuration = ArgoWorkflowsApiClient::Configuration.new.tap do |config|
      config.scheme = base_uri.scheme
      config.host = [base_uri.host, base_uri.port].compact.join(':')
      config.base_path = base_uri.path
      configure_auth(config, namespace:)
      config.timeout = ENV.fetch('ARGO_WORKFLOWS_TIMEOUT_SECONDS', 30).to_i

      # The in-cluster Argo endpoint uses a self-signed certificate.
      config.verify_ssl = false
      config.verify_ssl_host = false
    end

    { namespace:, client_configuration: }
  end

  def workflow_service_api
    @workflow_service_api
  end

  def configure_auth(config, namespace:)
    if env_present?('ARGO_WORKFLOWS_K8S_API_URL', 'ARGO_WORKFLOWS_K8S_CLUSTER_NAME', 'ARGO_WORKFLOWS_K8S_SERVICE_ACCOUNT')
      config.api_key['Authorization'] = kubernetes_service_account_token_requester(namespace:)
      config.api_key_prefix['Authorization'] = 'Bearer'
    elsif env_present?('ARGO_WORKFLOWS_USERNAME', 'ARGO_WORKFLOWS_PASSWORD')
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

  def kubernetes_service_account_token_requester(namespace:)
    KubernetesServiceAccountTokenRequester.new(
      api_url: ENV.fetch('ARGO_WORKFLOWS_K8S_API_URL'),
      cluster_name: ENV.fetch('ARGO_WORKFLOWS_K8S_CLUSTER_NAME'),
      namespace: ENV.fetch('ARGO_WORKFLOWS_K8S_NAMESPACE', namespace),
      service_account: ENV.fetch('ARGO_WORKFLOWS_K8S_SERVICE_ACCOUNT'),
      audience: ENV.fetch('ARGO_WORKFLOWS_K8S_TOKEN_AUDIENCE', 'https://kubernetes.default.svc'),
      expiration_seconds: ENV.fetch('ARGO_WORKFLOWS_K8S_TOKEN_EXPIRATION_SECONDS', 600)
    )
  end
end
