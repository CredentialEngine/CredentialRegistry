require_relative 'shared_examples/schema_validation'

# rubocop:todo RSpec/DescribeClass
RSpec.describe 'CERegistry LearningOpportunityProfile json-schema' do
  # rubocop:enable RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'ce_registry/learning_opportunity_profile'
end
