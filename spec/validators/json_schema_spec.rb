describe JSONSchema do
  it 'generate file path from schema_name' do
    json_schema = JSONSchema.new(:envelope)
    expect(json_schema.file_path).to match(%r{schemas/envelope.json.erb})
  end

  it 'checks if file exists' do
    json_schema = JSONSchema.new(:envelope)
    expect(json_schema.exist?).to eq(true)

    json_schema = JSONSchema.new(:nope)
    expect(json_schema.exist?).to eq(false)
  end

  it 'parse schema' do
    json_schema = JSONSchema.new(:envelope)
    expect(json_schema.schema).to be_a_kind_of(Hash)

    desc = json_schema.schema['description']
    expect(desc).to eq('MetadataRegistry data envelope')
  end

  it 'render erb template' do
    json_schema = JSONSchema.new(:json_ld)
    expect(json_schema.rendered).to be_a_kind_of(String)
    expect(json_schema.rendered).to_not be_empty
  end

  it 'prop add namespace to prefixed schemas' do
    json_schema = JSONSchema.new(:json_ld)
    expect(json_schema.prop('something')).to eq('something')

    json_schema = JSONSchema.new(:json_ld, 'jsonld')
    expect(json_schema.prop('something')).to eq('jsonld:something')
  end

  it 'renders partial templates' do
    json_schema = JSONSchema.new(:json_ld)
    partial = json_schema.partial('schemaorg/_person')

    expect(partial).to be_a_kind_of(String)
    expect(partial).to_not be_empty
    expect(JSON.parse(partial)).to be_a_kind_of(Hash)
  end
end
