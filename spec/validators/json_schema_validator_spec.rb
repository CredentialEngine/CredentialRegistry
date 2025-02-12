RSpec.describe JSONSchemaValidator do
  it 'parse schema' do
    validator = described_class.new(nil, :envelope)
    expect(validator.schema).to be_a(Hash)

    desc = validator.schema['description']
    expect(desc).to eq('MetadataRegistry data envelope')
  end

  context 'valid params' do # rubocop:todo RSpec/ContextWording
    let(:validator) do
      params = { name: 'Test resource', url: 'anyurl.com' }
      described_class.new(params, :learning_registry)
    end

    it 'validate the params' do
      expect(validator.validate).to be(true)

      expect(validator.valid?).to be(true)
      expect(validator.invalid?).to be(false)
    end

    it 'has no errors' do
      expect(validator.errors).to be_nil
    end
  end

  context 'invalid params' do # rubocop:todo RSpec/ContextWording
    let(:validator) do
      params = {
        name: 'Test resource',
        typicalAgeRange: 'bla',
        mediaType: ['invalid-type']
      }
      described_class.new(params, :learning_registry)
    end

    it 'validate the params' do
      expect(validator.validate).to be(false)

      expect(validator.valid?).to be(false)
      expect(validator.invalid?).to be(true)
    end

    it 'has errors' do
      validator.validate

      expect(validator.errors).to be_a(Hash)
    end

    it 'validate presence' do
      validator.validate
      expect(validator.errors['url']).to eq('is required')
    end

    it 'parse error message' do
      validator.validate

      expect(validator.errors['mediaType']).to match(
        /did not match one of the following values:/
      )
    end

    it 'use custom error message if exists' do
      validator.validate

      expect(validator.errors['typicalAgeRange']).to eq(
        "must be in one the following formats: '7', '7-12', '18-'"
      )
    end

    it 'has an error_messages array' do
      validator.validate

      expect(validator.error_messages).to be_a(Array)
      expect(validator.error_messages.size).to eq(3)
      expect(validator.error_messages).to include('url : is required')
    end
  end
end
