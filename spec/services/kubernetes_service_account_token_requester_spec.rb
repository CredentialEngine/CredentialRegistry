require 'spec_helper'

RSpec.describe KubernetesServiceAccountTokenRequester do
  let(:credentials_provider) { instance_double(Aws::Credentials) }
  let(:signer) { instance_double(Aws::Sigv4::Signer) }
  let(:presigned_url) do
    URI('https://sts.us-east-1.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15&X-Amz-SignedHeaders=host%3Bx-k8s-aws-id')
  end
  let(:token_request_body) do
    {
      kind: 'TokenRequest',
      apiVersion: 'authentication.k8s.io/v1',
      status: {
        token: 'short-lived-k8s-token',
        expirationTimestamp: 10.minutes.from_now.iso8601
      }
    }
  end

  subject(:requester) do
    described_class.new(
      api_url: 'https://k8s.example.test',
      cluster_name: 'cer-api-sandbox',
      namespace: 'cer-api-sandbox',
      service_account: 'credreg-app',
      audience: 'https://kubernetes.default.svc',
      expiration_seconds: 600,
      region: 'us-east-1',
      credentials_provider:
    )
  end

  before do
    allow(Aws::Sigv4::Signer).to receive(:new)
      .with(service: 'sts', region: 'us-east-1', credentials_provider:)
      .and_return(signer)
    allow(signer).to receive(:presign_url)
      .with(
        http_method: 'GET',
        url: 'https://sts.us-east-1.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15',
        headers: { 'x-k8s-aws-id' => 'cer-api-sandbox' },
        expires_in: 60
      ).and_return(presigned_url)

    stub_request(:post, 'https://k8s.example.test/api/v1/namespaces/cer-api-sandbox/serviceaccounts/credreg-app/token')
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => /^Bearer k8s-aws-v1\./,
          'Content-Type' => 'application/json'
        },
        body: {
          apiVersion: 'authentication.k8s.io/v1',
          kind: 'TokenRequest',
          spec: {
            audiences: ['https://kubernetes.default.svc'],
            expirationSeconds: 600
          }
        }.to_json
      )
      .to_return(status: 201, body: token_request_body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'requests and returns a short-lived Kubernetes service account token' do
    expect(requester.token).to eq('short-lived-k8s-token')
  end

  it 'reuses the token while it is not near expiration' do
    requester.token
    requester.token

    expect(WebMock).to have_requested(
      :post,
      'https://k8s.example.test/api/v1/namespaces/cer-api-sandbox/serviceaccounts/credreg-app/token'
    ).once
  end
end
