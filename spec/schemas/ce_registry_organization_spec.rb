require_relative 'shared_examples/schema_validation'

RSpec.describe 'CERegistry Organization json-schema' do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/organization'
end
