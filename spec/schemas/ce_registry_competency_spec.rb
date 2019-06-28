require_relative './shared_examples/schema_validation'

RSpec.describe 'CE/Registry Competency schema-json' do
  it_behaves_like 'json-schema validation', 'ce_registry/competency'
end
