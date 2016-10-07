require_relative './shared_examples/schema_validation'

describe 'CE/Registry Organization schema-json' do
  it_behaves_like 'json-schema validation', 'ce_registry/organization'
end
