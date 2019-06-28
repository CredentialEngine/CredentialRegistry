require_relative './shared_examples/schema_validation'

RSpec.describe 'LearningRegistry json-schema' do
  it_behaves_like 'json-schema validation', 'learning_registry'
end
