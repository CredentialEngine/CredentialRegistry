require_relative './shared_examples/schema_validation'

describe 'CERegistry Organization json-schema' do
  it_behaves_like 'json-schema validation', 'ce_registry/organization'
end
