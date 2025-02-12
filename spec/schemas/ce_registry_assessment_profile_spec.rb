require_relative 'shared_examples/schema_validation'

# rubocop:todo RSpec/DescribeClass
RSpec.describe 'CERegistry AssessmenteProfile json-schema', :broken do
  # rubocop:enable RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/assessment_profile'
end
