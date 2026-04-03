require 'spec_helper'

RSpec.describe ArgoWorkflowsClient do
  let(:api_client) { instance_double(ArgoWorkflowsApiClient::ApiClient) }
  let(:workflow_service_api) { instance_double(ArgoWorkflowsApiClient::WorkflowServiceApi) }
  let(:configuration) { instance_double(ArgoWorkflowsApiClient::Configuration) }
  let(:workflow) { { metadata: { name: 'ce-registry-download-abc123' } } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_NAMESPACE').and_return('credreg-staging')
    allow(ArgoWorkflowsApiClient::ApiClient).to receive(:new).with(configuration).and_return(api_client)
    allow(ArgoWorkflowsApiClient::WorkflowServiceApi)
      .to receive(:new).with(api_client).and_return(workflow_service_api)
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

  describe 'configuration auth' do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASE_URL').and_return('https://argo.example.test/api/v1')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_NAMESPACE').and_return('credreg-staging')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TIMEOUT_SECONDS', 30).and_return(30)
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_VERIFY_SSL', 'true').and_return('true')
      allow(ArgoWorkflowsApiClient::ApiClient).to receive(:new).and_return(api_client)
      allow(ArgoWorkflowsApiClient::WorkflowServiceApi).to receive(:new).and_return(workflow_service_api)
    end

    it 'uses bearer auth when only a token is configured' do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN', nil).and_return('secret-token')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASIC_AUTH_USER', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASIC_AUTH_PASSWORD', nil).and_return(nil)

      client = described_class.new
      config = client.send(:build_configuration)

      expect(config.auth_settings['BearerToken'][:value]).to eq('Bearer secret-token')
    end

    it 'uses basic auth when username and password are configured' do
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TOKEN', nil).and_return('secret-token')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASIC_AUTH_USER', nil).and_return('argo-user')
      allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BASIC_AUTH_PASSWORD', nil).and_return('argo-pass')

      client = described_class.new
      config = client.send(:build_configuration)

      expect(config.auth_settings['BearerToken'][:value]).to eq('Basic YXJnby11c2VyOmFyZ28tcGFzcw==')
    end
  end
end
