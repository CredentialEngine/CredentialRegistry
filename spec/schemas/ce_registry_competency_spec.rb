require_relative 'shared_examples/schema_validation'

RSpec.describe 'CE/Registry Competency schema-json' do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/competency'
end
