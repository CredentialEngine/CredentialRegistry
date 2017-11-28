require_relative './shared_examples/schema_validation'

describe 'Paradata json-schema' do
  it_behaves_like 'json-schema validation', 'paradata'
end
