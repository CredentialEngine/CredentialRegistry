require_relative './shared_examples/schema_validation'

describe 'CE/Registry LearningOpportunityProfile schema-json' do
  it_behaves_like 'json-schema validation',
                  'ce_registry/learning_opportunity_profile'
end
