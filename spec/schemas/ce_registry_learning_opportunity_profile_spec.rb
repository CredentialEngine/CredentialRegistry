require_relative './shared_examples/schema_validation'

RSpec.describe 'CERegistry LearningOpportunityProfile json-schema' do
  it_behaves_like 'json-schema validation', 'ce_registry/learning_opportunity_profile'
end
