describe SchemaRenderer do
  context 'json-schema' do
    it 'generate file path from schema_name' do
      config = SchemaRenderer.new(:envelope)
      expect(config.schema_file_path).to match(%r{schemas/envelope.json.erb})
    end

    it 'checks if file exists' do
      config = SchemaRenderer.new(:envelope)
      expect(config.schema_exist?).to eq(true)

      config = SchemaRenderer.new(:nope)
      expect(config.schema_exist?).to eq(false)
    end

    it 'parse schema' do
      config = SchemaRenderer.new(:envelope)
      expect(config.json_schema).to be_a_kind_of(Hash)

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
      config = SchemaRenderer.new(:json_ld)
      expect(config.rendered_schema).to be_a_kind_of(String)
      expect(config.rendered_schema).to_not be_empty
    end

    it '.rendered_schema raises SchemaDoesNotExist for invalid names' do
      expect { SchemaRenderer.new('non-valid').rendered_schema }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end

    it 'prop add namespace to prefixed schemas' do
      config = SchemaRenderer.new(:json_ld)
      expect(config.prop('something')).to eq('something')

      config = SchemaRenderer.new(:json_ld, 'jsonld')
      expect(config.prop('something')).to eq('jsonld:something')
    end

    it 'renders partial templates' do
      config = SchemaRenderer.new(:json_ld)
      partial = config.partial('schemaorg/_person')

      expect(partial).to be_a_kind_of(String)
      expect(partial).to_not be_empty
      expect(JSON.parse(partial)).to be_a_kind_of(Hash)
    end

    it '.all_schemas list all available configs' do
      configs = SchemaRenderer.all_schemas
      expect(configs.size).to be > 0
      expect(configs).to include('json_ld')
      expect(configs).to include('envelope')
    end
  end
end
