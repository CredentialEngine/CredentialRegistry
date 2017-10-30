require_relative './shared_examples/schema_validation'

describe 'CE/Registry CompetencyFramework schema-json' do
  it_behaves_like 'json-schema validation', 'ce_registry/competency_framework'
end
