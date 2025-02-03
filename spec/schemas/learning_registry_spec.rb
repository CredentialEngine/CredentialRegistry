require_relative 'shared_examples/schema_validation'

RSpec.describe 'LearningRegistry json-schema' do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'learning_registry'
end
