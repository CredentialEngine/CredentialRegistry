RSpec.shared_examples 'json-schema validation' do |schema|
  let(:schema) { schema }
  let(:path) { MR.root_path.join('db', 'seeds') + "#{schema}.json" }
  let(:fixture) { JSON.parse File.read(path) }

  it 'checks if has resources to test' do
    expect(File.exist?(path)).to be true
    expect(fixture).to be_a(Array)
    expect(fixture.first).to be_a(Hash)
  end

  it 'validates' do
    fixture.each do |data|
      validator = JSONSchemaValidator.new(data, schema)
      expect(validator.validate).to be(true), "#{schema} :: #{validator.errors}\n\n#{data}"
    end
  end
end
