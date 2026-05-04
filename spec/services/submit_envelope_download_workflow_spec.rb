require 'spec_helper'

RSpec.describe SubmitEnvelopeDownloadWorkflow do
  let(:client) { instance_double(ArgoWorkflowsClient, namespace: 'credreg-staging') }
  let(:community) { EnvelopeCommunity.find_or_create_by!(name: 'ce_registry') }
  let(:envelope_download) { create(:envelope_download, envelope_community: community) }
  let(:workflow) { { metadata: { name: 'ce-registry-download-abc123' } } }
  let(:now) { Time.zone.parse('2026-03-06 12:00:00 UTC') }

  before do
    allow(ArgoWorkflowsClient).to receive(:new).and_return(client)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_TASK_IMAGE').and_return('registry:s3-graphs-zip')
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_BATCH_SIZE', '25000').and_return('25000')
    allow(ENV).to receive(:fetch)
      .with('ARGO_WORKFLOWS_MAX_UNCOMPRESSED_ZIP_SIZE_BYTES', '209715200')
      .and_return('209715200')
    allow(ENV).to receive(:fetch).with('ARGO_WORKFLOWS_MAX_WORKERS', '4').and_return('4')
    allow(ENV).to receive(:fetch).with('AWS_REGION').and_return('us-east-1')
    allow(ENV).to receive(:fetch).with('ENVELOPE_DOWNLOADS_BUCKET').and_return('downloads-bucket')
    allow(ENV).to receive(:fetch).with('ENVELOPE_GRAPHS_BUCKET').and_return('graphs-bucket')
  end

  it 'submits the workflow and marks the download in progress' do
    allow(client).to receive(:submit_workflow)
      .with(
        template_name: 's3-graphs-zip',
        generate_name: 'ce-registry-download-',
        parameters: {
          'batch-size' => '25000',
          'aws-region' => 'us-east-1',
          'destination-bucket' => 'downloads-bucket',
          'destination-prefix' => "ce_registry/downloads/#{envelope_download.id}",
          'environment' => MR.env,
          'max-uncompressed-zip-size-bytes' => '209715200',
          'max-workers' => '4',
          'source-bucket' => 'graphs-bucket',
          'source-prefix' => 'ce_registry',
          'task-image' => 'registry:s3-graphs-zip'
        }
      ).and_return(workflow)

    travel_to now do
      described_class.call(envelope_download:)
    end

    envelope_download.reload
    expect(envelope_download.status).to eq('in_progress')
    expect(envelope_download.started_at).to eq(now)
    expect(envelope_download.finished_at).to be_nil
    expect(envelope_download.internal_error_message).to be_nil
    expect(envelope_download.argo_workflow_name).to eq('ce-registry-download-abc123')
    expect(envelope_download.argo_workflow_namespace).to eq('credreg-staging')
    expect(envelope_download.zip_files).to eq([])
  end

  it 'does not submit a second workflow when one is already in progress' do
    envelope_download.update!(
      argo_workflow_name: 'existing-workflow',
      argo_workflow_namespace: 'credreg-staging',
      status: :in_progress
    )

    expect(client).not_to receive(:submit_workflow)

    described_class.call(envelope_download:)

    expect(envelope_download.reload.argo_workflow_name).to eq('existing-workflow')
  end
end
