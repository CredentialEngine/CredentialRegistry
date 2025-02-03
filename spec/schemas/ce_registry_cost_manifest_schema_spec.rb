require_relative 'shared_examples/schema_validation'

RSpec.describe 'CERegistry CostManifest json-schema' do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/cost_manifest_schema'
end
