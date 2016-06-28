require_relative './shared_examples/schema_validation'

describe 'CredentialRegistry Credential schema-json' do
  it_behaves_like 'json-schema validation', 'credential_registry/credential'
end
