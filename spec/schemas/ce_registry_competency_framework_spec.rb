require_relative './shared_examples/schema_validation'

RSpec.describe 'CERegistry CompetencyFramework json-schema' do
  it_behaves_like 'json-schema validation', 'ce_registry/competency_framework'
end
