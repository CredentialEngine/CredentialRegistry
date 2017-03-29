describe API::V1::Schemas do
  context 'GET /api/schemas/info' do
    before(:each) do
      get '/api/schemas/info'
    end

    it { expect_status(:ok) }

    it 'returns a list of available schemas' do
      expect_json_types(specification: :string,
                        available_schemas: :array_of_strings)
    end
  end

  context 'GET /api/schemas/:schema_name' do
    before(:each) do
      get "/api/schemas/#{schema_name}"
    end

    context 'valid schema' do
      let(:schema_name) { :envelope }

      it { expect_status(:ok) }

      it 'retrieves the desired schema' do
        expect_json(description: 'MetadataRegistry data envelope')
      end

      context 'community composed names' do
        let(:schema_name) { 'ce_registry/credential' }

        it { expect_status(:ok) }
      end
    end

    context 'invalid schema' do
      let(:schema_name) { :nope }

      it { expect_status(:not_found) }
    end
  end

  context 'PUT /api/schema/:schema_name' do
    before(:each) { create(:envelope_community, name: 'learning_registry') }

    let(:schema_resource) do
      {
        name: 'learning_registry',
        schema: {
          properties: {
            something: { type: 'string' }
          },
          required: ['something']
        }
      }
    end

    let(:envelope) do
      attributes_for(:envelope,
                     envelope_type: 'json_schema',
                     resource: jwt_encode(schema_resource))
    end

    let(:modified_envelope) do
      attributes_for(
        :envelope,
        envelope_type: 'json_schema',
        resource: jwt_encode(
          name: 'learning_registry',
          schema: { properties: {} }
        )
      )
    end

    let(:wrong_key) do
      '-----BEGIN RSA PUBLIC KEY-----\n'\
      'MIIBCgKCAQEAwaqtYs08xvCqIC/E5zR2f7jMc4I5gXfmPr8bd8JrLGjm2cx68AAp\n'\
      '6KwKnT+NqwbM5wozY7TOMIamUE07RNfgv7bpqu/ipQ1ddWM8f1X6thUUKJdlj3RK\n'\
      'sIehNzjPd7/8qnAiBva3XGjFSqeLTOOpSzRe4la3eVLXDX3LylO5C3Mv/r081aKu\n'\
      'k9ThdMV6VJDU0ivKvD0R7eHlZ7BzpH9n+RaNhUB63HzhNEJGt3WFcPGEItzl2X95\n'\
      'IB+HCET3lCWRmfEV+xyYoWfi0l/jnGDjJpzLKjqvdpvourThdqDUWSBVwpsVQ3Jg\n'\
      'G6XXfSWwNXg5Ew7s5ET/l6HNvh+ms5ejywIDAQAB\n'\
      '-----END RSA PUBLIC KEY-----'
    end

    it 'updates the schema' do
      old_schema = JsonSchema.for('learning_registry').schema

      put '/api/schemas/learning_registry', envelope

      expect_status(:ok)
      new_schema = JsonSchema.for('learning_registry').schema
      expect(new_schema).to_not eq(old_schema)
      expect(new_schema).to eq(schema_resource[:schema].with_indifferent_access)
    end

    it 'update the same envelope using the schema_name as identifier' do
      put '/api/schemas/learning_registry', envelope
      expect_status(:ok)
      json_schema = JsonSchema.for('learning_registry')
      expect(json_schema.schema).to eq(
        schema_resource[:schema].with_indifferent_access
      )

      put '/api/schemas/learning_registry', modified_envelope
      expect_status(:ok)
      expect(json_schema.reload.schema).to eq('properties' => {})
    end

    it 'requires an authorized key' do
      put '/api/schemas/learning_registry',
          envelope.merge(resource_public_key: wrong_key)

      expect_json('errors.0', /Unauthorized public_key/)
      expect(JsonSchema.for('learning_registry').schema).to_not eq(
        schema_resource[:schema].with_indifferent_access
      )
    end

    context 'invalid schema' do
      let(:invalid_schema) { { schema: { properties: {} } } }
      let(:modified_envelope) do
        attributes_for(
          :envelope,
          envelope_type: 'json_schema',
          resource: jwt_encode(invalid_schema)
        )
      end

      before(:each) do
        put '/api/schemas/learning_registry', modified_envelope
      end

      it { expect_status(:not_found) }

      it 'returns error messages' do
        expect_json('errors.0', /name : is required/)
      end

      it "doesn't update the schema" do
        expect(JsonSchema.for('learning_registry').schema).not_to eq(
          invalid_schema[:schema].with_indifferent_access
        )
      end
    end

    context 'invalid schema name' do
      before(:each) do
        put '/api/schemas/nope', envelope
      end

      it { expect_status(:not_found) }
    end
  end
end
