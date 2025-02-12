RSpec.describe SchemaRenderer do
  context 'json-schema' do # rubocop:todo RSpec/ContextWording
    it 'generate file path from schema_name' do
      config = described_class.new(:envelope)
      expect(config.schema_file_path).to match(%r{schemas/envelope.json.erb})
    end

    it 'checks if file exists' do
      config = described_class.new(:envelope)
      expect(config.schema_exist?).to be(true)

      config = described_class.new(:nope)
      expect(config.schema_exist?).to be(false)
    end

    it 'parse schema' do
      config = described_class.new(:envelope)
      expect(config.json_schema).to be_a(Hash)

      desc = config.json_schema['description']
      expect(desc).to eq('MetadataRegistry data envelope')
    end

    # it 'parse public schema if a request is provided' do
    #   req = double(base_url: 'http://example.com')
    #   schema = SchemaRenderer.new(:envelope).json_schema(req)

    #   expect(schema).to be_a_kind_of(Hash)
    #   expect(schema.to_s).to include('http://example.com/schemas/')
    # end

    it 'render erb template' do
      config = described_class.new(:json_ld)
      expect(config.rendered_schema).to be_a(String)
      expect(config.rendered_schema).not_to be_empty
    end

    it '.rendered_schema raises SchemaDoesNotExist for invalid names' do
      expect { described_class.new('non-valid').rendered_schema }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end

    it 'prop add namespace to prefixed schemas' do
      config = described_class.new(:json_ld)
      expect(config.prop('something')).to eq('something')

      config = described_class.new(:json_ld, 'jsonld')
      expect(config.prop('something')).to eq('jsonld:something')
    end

    it 'renders partial templates' do
      config = described_class.new(:json_ld)
      partial = config.partial('schemaorg/_person')

      expect(partial).to be_a(String)
      expect(partial).not_to be_empty
      expect(JSON.parse(partial)).to be_a(Hash)
    end

    it '.all_schemas list all available configs' do
      configs = described_class.all_schemas
      expect(configs.size).to be > 0
      expect(configs).to include('json_ld')
      expect(configs).to include('envelope')
    end
  end
end
