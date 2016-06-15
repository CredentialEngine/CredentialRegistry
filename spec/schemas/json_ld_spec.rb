require_relative './shared_examples/schema_validation'

describe 'JSON-LD schema-json' do
  it_behaves_like 'json-schema validation', :json_ld
end
