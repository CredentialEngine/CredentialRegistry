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
end
