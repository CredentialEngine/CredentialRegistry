shared_examples 'json-schema validation' do |schema|
  let(:base_path) { '../../../support/fixtures' }

  context 'valid resource' do
    let(:resource) do
      path = File.expand_path("#{base_path}/#{schema}_valid.json", __FILE__)
      JSON.parse File.read(path)
    end
    let(:validator) { JSONSchemaValidator.new(resource, schema) }

    before { validator.validate }

    it { expect(validator.valid?).to eq(true) }
    it { expect(validator.errors).to be_nil }
  end

  context 'invalid resource' do
    let(:resource) do
      path = File.expand_path("#{base_path}/#{schema}_invalid.json", __FILE__)
      JSON.parse File.read(path)
    end
    let(:validator) { JSONSchemaValidator.new(resource, schema) }

    before { validator.validate }

    it { expect(validator.valid?).to eq(false) }
    it { expect(validator.errors).to be_a_kind_of(Hash) }
  end
end
