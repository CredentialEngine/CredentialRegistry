require_relative './shared_examples/schema_validation'

describe 'CE/Registry AssessmenteProfile schema-json' do
  it_behaves_like 'json-schema validation', 'ce_registry/assessment_profile'
end
