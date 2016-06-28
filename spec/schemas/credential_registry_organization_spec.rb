require_relative './shared_examples/schema_validation'

describe 'CredentialRegistry Organization schema-json' do
  it_behaves_like 'json-schema validation', 'credential_registry/organization'
end
