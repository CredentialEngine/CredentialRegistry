require 'submit_changeset_workflow'

require 'spec_helper'

RSpec.describe SubmitChangesetWorkflow do
  let(:client) { instance_double(ArgoWorkflowsClient, namespace: 'credreg-staging') }
  let(:community) { EnvelopeCommunity.find_or_create_by!(name: 'ce_registry') }
  let(:workflow) { { metadata: { name: 'ce-registry-apply-changeset-graphs-abc123' } } }

  before do
    allow(ArgoWorkflowsClient).to receive(:new).and_return(client)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TASK_IMAGE').and_return('registry:workflow-tasks')
    allow(ENV).to receive(:fetch).with('ENVELOPE_GRAPHS_BUCKET').and_return('graphs-bucket')
    allow(ENV).to receive(:fetch).with('AWS_REGION').and_return('us-east-1')
    allow(ENV).to receive(:[]).with('ELASTICSEARCH_URL').and_return('https://es.example.test')
    allow(ENV).to receive(:[]).with('ELASTICSEARCH_USERNAME').and_return('elastic')
    allow(ENV).to receive(:[]).with('ELASTICSEARCH_PASSWORD').and_return('secret')
    allow(ENV).to receive(:[]).with('AWS_S3_SERVICE_URL').and_return(nil)
  end

  it 'submits the apply changeset workflow' do
    allow(client).to receive(:submit_workflow)
      .with(
        template_name: 'apply-changeset',
        generate_name: 'ce-registry-apply-changeset-graphs-',
        parameters: {
          'elasticsearch-url' => 'https://es.example.test',
          'elasticsearch-username' => 'elastic',
          'elasticsearch-password' => 'secret',
          'task-image' => 'registry:workflow-tasks',
          'entity-type' => 'graphs',
          'input-bucket' => 'graphs-bucket',
          'input-file-key' => 'ce_registry/changesets/manifests/graphs-2026.gz',
          'source-bucket' => 'graphs-bucket',
          'target-bucket' => 'graphs-bucket',
          'aws-region' => 'us-east-1'
        }
      ).and_return(workflow)

    result = described_class.call(
      envelope_community: community,
      entity_type: :graphs,
      manifest_key: 'ce_registry/changesets/manifests/graphs-2026.gz'
    )

    expect(result).to eq(workflow.merge(namespace: 'credreg-staging'))
  end
end
