require_relative './shared_examples/schema_validation'

describe 'LearningRegistry schema-json' do
  it_behaves_like 'json-schema validation', :learning_registry
end
