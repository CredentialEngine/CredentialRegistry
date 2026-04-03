require 'base64'
require 'spec_helper'

RSpec.describe ArgoWorkflowsClient do
  let(:api_client) { instance_double(ArgoWorkflowsApiClient::ApiClient) }
  let(:workflow_service_api) { instance_double(ArgoWorkflowsApiClient::WorkflowServiceApi) }
  let(:configuration) { instance_double(ArgoWorkflowsApiClient::Configuration) }
  let(:workflow) { { metadata: { name: 'ce-registry-download-abc123' } } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_NAMESPACE').and_return('credreg-staging')
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN').and_return('static-argo-token')
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_USERNAME', nil).and_return(nil)
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_PASSWORD', nil).and_return(nil)
    unless configuration.nil?
      allow(api_client).to receive(:config).and_return(configuration)
      allow(configuration).to receive(:api_key).and_return({})
      allow(configuration).to receive(:api_key_prefix).and_return({})
    end
    allow(ArgoWorkflowsApiClient::ApiClient).to receive(:new).with(configuration).and_return(api_client)
    allow(ArgoWorkflowsApiClient::WorkflowServiceApi)
      .to receive(:new).with(api_client).and_return(workflow_service_api)
    allow(workflow_service_api).to receive(:api_client).and_return(api_client)
  end

  describe '#submit_workflow' do
    it 'passes generateName and parameters to the Argo client' do
      client = described_class.new(configuration:)

      allow(workflow_service_api).to receive(:workflow_service_submit_workflow)
        .with(
          {
            namespace: 'credreg-staging',
            resourceKind: 'WorkflowTemplate',
            resourceName: 's3-graphs-zip',
            submitOptions: {
              generateName: 'ce-registry-download-',
              parameters: ['source-prefix=ce_registry', 'destination-bucket=downloads-bucket']
            }
          },
          'credreg-staging',
          return_type: 'Object'
        ).and_return(workflow)

      result = client.submit_workflow(
        template_name: 's3-graphs-zip',
        generate_name: 'ce-registry-download-',
        parameters: {
          'source-prefix' => 'ce_registry',
          'destination-bucket' => 'downloads-bucket'
        }
      )

      expect(result).to eq(workflow)
    end
  end

  describe 'configuration' do
    let(:configuration) { nil }
    let(:built_configuration) { ArgoWorkflowsApiClient::Configuration.new }

    before do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASE_URL').and_return('https://argo.example.test/workflows')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TIMEOUT_SECONDS', 30).and_return(30)
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_USERNAME', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_PASSWORD', nil).and_return(nil)
      allow(ArgoWorkflowsApiClient::Configuration).to receive(:new).and_return(built_configuration)
      allow(ArgoWorkflowsApiClient::ApiClient).to receive(:new).with(built_configuration).and_return(api_client)
      allow(api_client).to receive(:config).and_return(built_configuration)
    end

    it 'uses ARGO_WORKFLOWS_TOKEN when Basic auth is not configured' do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN').and_return('static-argo-token')

      allow(workflow_service_api).to receive(:workflow_service_get_workflow).and_return(workflow)

      described_class.new.get_workflow(name: 'ce-registry-download-abc123')

      expect(built_configuration.api_key['Authorization']).to eq('static-argo-token')
      expect(built_configuration.api_key_prefix['Authorization']).to eq('Bearer')
    end

    it 'uses Basic auth when Basic auth is configured' do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_USERNAME', nil).and_return('argo-user')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_PASSWORD', nil).and_return('argo-password')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_USERNAME').and_return('argo-user')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_PASSWORD').and_return('argo-password')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN').and_return('static-argo-token')

      allow(workflow_service_api).to receive(:workflow_service_get_workflow).and_return(workflow)

      described_class.new.get_workflow(name: 'ce-registry-download-abc123')

      expect(built_configuration.api_key['Authorization']).to eq(Base64.strict_encode64('argo-user:argo-password'))
      expect(built_configuration.api_key_prefix['Authorization']).to eq('Basic')
    end

    it 'disables SSL verification for the in-cluster Argo endpoint' do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN').and_return('static-argo-token')
      allow(workflow_service_api).to receive(:workflow_service_get_workflow).and_return(workflow)

      described_class.new.get_workflow(name: 'ce-registry-download-abc123')

      expect(built_configuration.verify_ssl).to be(false)
      expect(built_configuration.verify_ssl_host).to be(false)
    end
  end
end
