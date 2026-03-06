require 'spec_helper'

RSpec.describe SyncEnvelopeDownloadWorkflowStatus do
  let(:client) { instance_double(ArgoWorkflowsClient) }
  let(:community) { EnvelopeCommunity.find_or_create_by!(name: 'ce_registry') }
  let(:envelope_download) do
    create(
      :envelope_download,
      :in_progress,
      envelope_community: community,
      argo_workflow_name: 'ce-registry-download-abc123',
      argo_workflow_namespace: 'credreg-staging'
    )
  end
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_resource) { instance_double(Aws::S3::Resource) }
  let(:bucket) { instance_double(Aws::S3::Bucket) }
  let(:object) { instance_double(Aws::S3::Object, public_url: 'https://downloads.example/batch-00001.zip') }

  before do
    allow(ArgoWorkflowsClient).to receive(:new).and_return(client)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('AWS_REGION').and_return('us-east-1')
    allow(ENV).to receive(:fetch).with('ENVELOPE_DOWNLOADS_BUCKET').and_return('downloads-bucket')
  end

  context 'when the workflow succeeds' do
    before do
      allow(client).to receive(:get_workflow).with(name: 'ce-registry-download-abc123').and_return(
        status: {
          phase: 'Succeeded',
          finishedAt: '2026-03-06T12:10:00Z',
          outputs: {
            parameters: [
              {
                name: 'zip-manifest',
                value: {
                  batch_count: 2,
                  destination_bucket: 'downloads-bucket',
                  destination_prefix: "ce_registry/downloads/#{envelope_download.id}",
                  total_files: 12,
                  total_input_bytes: 123_456,
                  zip_files: [
                    "ce_registry/downloads/#{envelope_download.id}/batch-00001.zip",
                    "ce_registry/downloads/#{envelope_download.id}/batch-00002.zip",
                  ],
                  zip_size_bytes: 45_678,
                }.to_json
              },
            ]
          }
        }
      )

      allow(Aws::S3::Client).to receive(:new).with(region: 'us-east-1').and_return(s3_client)
      allow(s3_client).to receive(:head_object).with(
        bucket: 'downloads-bucket',
        key: "ce_registry/downloads/#{envelope_download.id}/batch-00001.zip"
      ).and_return(true)

      allow(Aws::S3::Resource).to receive(:new).with(region: 'us-east-1').and_return(s3_resource)
      allow(s3_resource).to receive(:bucket).with('downloads-bucket').and_return(bucket)
      allow(bucket).to receive(:object)
        .with("ce_registry/downloads/#{envelope_download.id}/batch-00001.zip")
        .and_return(object)
    end

    it 'stores the download URL and marks the download finished' do
      described_class.call(envelope_download:)

      envelope_download.reload
      expect(envelope_download.status).to eq('finished')
      expect(envelope_download.url).to eq('https://downloads.example/batch-00001.zip')
      expect(envelope_download.zip_files).to eq(
        [
          "ce_registry/downloads/#{envelope_download.id}/batch-00001.zip",
          "ce_registry/downloads/#{envelope_download.id}/batch-00002.zip",
        ]
      )
      expect(envelope_download.internal_error_message).to be_nil
      expect(envelope_download.finished_at).to eq(Time.zone.parse('2026-03-06T12:10:00Z'))
    end
  end

  context 'when the workflow fails' do
    before do
      allow(client).to receive(:get_workflow).with(name: 'ce-registry-download-abc123').and_return(
        status: {
          phase: 'Failed',
          finishedAt: '2026-03-06T12:10:00Z',
          message: 'zip task failed'
        }
      )
    end

    it 'marks the download failed' do
      described_class.call(envelope_download:)

      envelope_download.reload
      expect(envelope_download.status).to eq('finished')
      expect(envelope_download.url).to be_nil
      expect(envelope_download.zip_files).to eq([])
      expect(envelope_download.internal_error_message).to eq('zip task failed')
      expect(envelope_download.finished_at).to eq(Time.zone.parse('2026-03-06T12:10:00Z'))
    end
  end
end
