require_relative './shared_examples/schema_validation'

describe 'Envelope schema-json' do
  it_behaves_like 'json-schema validation', :envelope
end
