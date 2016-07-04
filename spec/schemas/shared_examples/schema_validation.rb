shared_examples 'json-schema validation' do |schema|
  let(:schema) { schema }
  let(:base_path) do
    File.expand_path('../../../support/fixtures/json', __FILE__)
  end

  def json_paths(type)
    # ex:
    #     # type: :valid, schema: :learning_registry
    #     >> support/fixtures/json/learning_registry/anything_valid.json
    Dir.glob("#{base_path}/#{schema}/*_#{type}.json").to_a
  end

  def ref(path)
    "#{schema}/#{path.split('/').last}"
  end

  context 'valid resources' do
    it 'checks if has resources to test' do
      expect(json_paths(:valid)).to_not be_empty
    end

    it 'validates' do
      json_paths(:valid).each do |path|
        data = JSON.parse File.read(path)
        validator = JSONSchemaValidator.new(data, schema)

        expect(validator.validate).to eq(true), "#{ref path} should be valid"
        expect(validator.errors).to be_nil, "#{ref path} should have no errors"
      end
    end
  end

  context 'invalid resources' do
    it 'checks if has resources to test' do
      expect(json_paths(:invalid)).to_not be_empty
    end

    it 'invalidates' do
      json_paths(:invalid).each do |path|
        data = JSON.parse File.read(path)
        validator = JSONSchemaValidator.new(data, schema)

        expect(validator.validate).to eq(false), "#{ref path} should be invalid"
        expect(validator.errors).to_not be_nil, "#{ref path} should have errors"
      end
    end
  end
end
