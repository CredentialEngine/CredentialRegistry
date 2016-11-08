describe API::V1::Schemas do
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

  context 'json_schema envelope' do
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
      expect do
        post '/api/learning-registry/envelopes', envelope
      end.to change { Envelope.schemas.count }.by(1)

      expect_status(:created)
      expect(SchemaConfig.new('learning_registry').json_schema).to eq(
        schema_resource[:schema].with_indifferent_access
      )
    end

    it 'schema name must be unique' do
      post '/api/learning-registry/envelopes', envelope
      expect_status(:created)

      post '/api/learning-registry/envelopes',
           envelope.merge(envelope_id: 'anything-wlse')
      expect_status(:unprocessable_entity)
      expect_json('errors.0', /schema name must be unique/i)
    end

    it 'requires an authorized key' do
      expect do
        post '/api/learning-registry/envelopes',
             envelope.merge(resource_public_key: wrong_key)
      end.to_not change { Envelope.schemas.count }

      expect_json('errors.0', /Unauthorized public_key/)
    end
  end
end
