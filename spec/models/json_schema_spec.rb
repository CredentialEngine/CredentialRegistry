describe JsonSchema, type: :model do
  describe 'update_from_fixture' do
    let(:name) { 'ce_registry/competency' }
    let(:empty_schema) { { empty: true } }
    let!(:json_schema) { JsonSchema.create(name: name, schema: empty_schema) }

    it 'update schema using the fixture file' do
      expect(JsonSchema.update_from_fixture!(name)).to be true
      schema = json_schema.reload.schema
      expect(schema).to_not equal(empty_schema)
      expect(schema['$ref']).to eq '#/definitions/ceasn:Competency'
    end
  end
end
