require_relative 'shared_examples/schema_validation'

RSpec.describe 'Paradata json-schema' do # rubocop:todo RSpec/DescribeClass
  it_behaves_like 'json-schema validation', 'paradata'
end
