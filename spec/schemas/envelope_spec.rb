require_relative './shared_examples/schema_validation'

RSpec.describe 'Envelope json-schema' do
  it_behaves_like 'json-schema validation', :envelope
end
