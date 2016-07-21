require_relative './shared_examples/schema_validation'

describe 'Paradata schema-json' do
  it_behaves_like 'json-schema validation', :paradata
end
