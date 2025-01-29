require_relative 'shared_examples/schema_validation'

RSpec.describe 'CERegistry Credential json-schema', :broken do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/credential'
end
