describe SchemaConfig do
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

  it 'render erb template' do
    config = SchemaConfig.new(:json_ld)
    expect(config.rendered_schema).to be_a_kind_of(String)
    expect(config.rendered_schema).to_not be_empty
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
end
