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
    expect(desc).to eq('LearningRegistry data envelope')
  end
end
