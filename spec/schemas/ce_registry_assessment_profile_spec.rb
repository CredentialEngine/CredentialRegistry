require_relative './shared_examples/schema_validation'

describe 'CERegistry AssessmenteProfile json-schema' do
  it_behaves_like 'json-schema validation', 'ce_registry/assessment_profile'
end
