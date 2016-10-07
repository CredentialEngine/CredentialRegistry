describe SchemaConfig do
  context 'json-schema' do
    it 'generate file path from schema_name' do
      config = SchemaConfig.new(:envelope)
      expect(config.schema_file_path).to match(%r{schemas/envelope.json.erb})
    end

    it 'checks if file exists' do
      config = SchemaConfig.new(:envelope)
      expect(config.schema_exist?).to eq(true)

      config = SchemaConfig.new(:nope)
      expect(config.schema_exist?).to eq(false)
    end

    it 'parse schema' do
      config = SchemaConfig.new(:envelope)
      expect(config.json_schema).to be_a_kind_of(Hash)

      desc = config.json_schema['description']
      expect(desc).to eq('MetadataRegistry data envelope')
    end

    it 'parse public schema if a request is provided' do
      req = double(base_url: 'http://example.com')
      schema = SchemaConfig.new(:envelope).json_schema(req)

      expect(schema).to be_a_kind_of(Hash)
      expect(schema.to_s).to include('http://example.com/api/schemas/')
    end

    it 'render erb template' do
      config = SchemaConfig.new(:json_ld)
      expect(config.rendered_schema).to be_a_kind_of(String)
      expect(config.rendered_schema).to_not be_empty
    end

    it '.rendered_Schema raises SchemaDoesNotExist for invalid names' do
      expect { SchemaConfig.new('non-valid').rendered_schema }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end

    it 'prop add namespace to prefixed schemas' do
      config = SchemaConfig.new(:json_ld)
      expect(config.prop('something')).to eq('something')

      config = SchemaConfig.new(:json_ld, 'jsonld')
      expect(config.prop('something')).to eq('jsonld:something')
    end

    it 'renders partial templates' do
      config = SchemaConfig.new(:json_ld)
      partial = config.partial('schemaorg/_person')

      expect(partial).to be_a_kind_of(String)
      expect(partial).to_not be_empty
      expect(JSON.parse(partial)).to be_a_kind_of(Hash)
    end

    it '.all_schemas list all available configs' do
      configs = SchemaConfig.all_schemas
      expect(configs.size).to be > 0
      expect(configs).to include('json_ld')
      expect(configs).to include('envelope')
    end
  end

  context 'config' do
    it '.all_configs list all available configs' do
      configs = SchemaConfig.all_configs
      expect(configs.size).to be > 0
      expect(configs).to include('learning_registry')
      expect(configs).to include('ce_registry')
    end

    it '#config provide the community config' do
      config = SchemaConfig.new('learning_registry').config
      expect(config).to be_a_kind_of(Hash)
    end

    it '#config resource_type configs can be nested on communities' do
      comm_config = SchemaConfig.new('ce_registry').config
      type_config = SchemaConfig.new('ce_registry/organization').config
      expect(type_config).to be_a_kind_of(Hash)
      expect(type_config).to_not be_empty
      expect(comm_config['organization']).to eq type_config
    end

    it '#config raise MR::SchemaDoesNotExist for invalid names' do
      expect { SchemaConfig.new('non-valid').config }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end
  end
end
