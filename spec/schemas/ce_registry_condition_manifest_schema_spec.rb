require_relative './shared_examples/schema_validation'

RSpec.describe 'CERegistry ConditionManifest json-schema' do
  it_behaves_like 'json-schema validation', 'ce_registry/condition_manifest_schema'
end
