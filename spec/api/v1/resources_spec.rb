describe API::V1::Resources do
  context 'default community' do
    let!(:ec)       { create(:envelope_community, name: 'ce_registry') }
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let(:resource) { envelope.processed_resource }
    let(:full_id)  { resource['@id'] }
    let(:id)       { full_id.split('/').last }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:resource_json) do
      content = File.read MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
      JSON.parse(content).first.to_json
    end

    context 'CREATE /resources' do
      before do
        post '/resources', attributes_for(:envelope, :from_cer,
                                          envelope_community: ec.name)
      end

      it 'returns a 201 Created http status code' do
        expect_status(:created)
      end

      context 'returns the newly created envelope' do
        it { expect_json_types(envelope_id: :string) }
        it { expect_json_types(envelope_ceterms_ctid: :string) }
        it { expect_json_types(envelope_ctdl_type: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '0.52.0') }
      end
    end

    context 'CREATE /resources to update' do
      before(:each) do
        update  = jwt_encode(resource.merge('ceterms:name': 'Updated'))
        payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                                 resource: update,
                                 envelope_community: ec.name)
        post '/resources/', payload
        envelope.reload
      end

      it { expect_status(:ok) }

      it 'updates some data inside the resource' do
        expect(envelope.processed_resource['ceterms:name']).to eq('Updated')
      end
    end

    context 'CREATE /resources to update - updates for graph URL' do
      before(:each) do
        update = jwt_encode(
          resource.merge(
            'ceterms:name': 'Updated',
            '@id': resource['@id'].gsub('/resources', '/graph')
          )
        )
        payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                                 resource: update,
                                 envelope_community: ec.name)
        post '/resources/', payload
        envelope.reload
      end

      it { expect_status(:ok) }

      it 'updates some data inside the resource' do
        expect(envelope.processed_resource['ceterms:name']).to eq('Updated')
      end
    end

    context 'GET /resources/:id' do
      let(:ctid) { Faker::Lorem.characters(10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{ctid}"
      end
      let(:id_field) {}
      let(:resource_with_ids) do
        resource.merge('@id' => full_id, 'ceterms:ctid' => ctid)
      end

      before(:each) do
        allow_any_instance_of(EnvelopeCommunity)
          .to receive(:id_field).and_return(id_field)

        create(
          :envelope,
          :from_cer,
          :with_cer_credential,
          envelope_community: ec,
          resource: jwt_encode(resource_with_ids),
          skip_validation: true
        )

        get "/resources/#{CGI.escape(id)}"
      end

      context 'without `id_field`' do
        context 'by full ID' do
          let(:id) { full_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by short ID' do
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
      end

      context 'with `id_field`' do
        let(:id_field) { 'ceterms:ctid' }

        context 'by custom ID' do
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by custom ID, downcase' do
          let(:id) { ctid.downcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by custom ID, upcase' do
          let(:id) { ctid.upcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by full ID' do
          let(:id) { full_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by short ID' do
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
      end

      context 'with graph resources' do
        let(:id_field) { 'ceterms:ctid' }
        let(:resource_with_ids) do
          attributes_for(:cer_graph_competency_framework, ctid: ctid)
        end

        context 'by ID internal to the graph' do
          let(:competency_id) do
            resource_with_ids[:'@graph']
              .find { |obj| obj[:'@type'] == 'ceasn:Competency' }[:'ceterms:ctid']
          end
          let(:full_competency_id) do
            "http://credentialengineregistry.org/resources/#{competency_id}"
          end

          context 'upcase' do
            let(:id) { competency_id.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_competency_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end

          context 'downcase' do
            let(:id) { competency_id.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_competency_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
        end

        context 'by primary ID' do
          context 'upcase' do
            let(:id) { ctid.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end

          context 'downcase' do
            let(:id) { ctid.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
        end

        context 'by bnode ID' do
          let(:id) do
            resource_with_ids[:'@graph']
              .find { |obj| obj[:'@id'].start_with?('_') }[:'ceterms:ctid']
          end

          it 'cannot retrieve the desired resource' do
            expect_status(:not_found)
          end
        end
      end
    end

    context 'PUT /resources/:id' do
      before(:each) do
        update  = jwt_encode(resource.merge('ceterms:name': 'Updated'))
        payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                                 resource: update,
                                 envelope_community: ec.name)
        put "/resources/#{id}", payload
        envelope.reload
      end

      it { expect_status(:ok) }

      it 'updates some data inside the resource' do
        expect(envelope.processed_resource['ceterms:name']).to eq('Updated')
      end
    end

    context 'DELETE /resources/:id' do
      before(:each) do
        payload = attributes_for(:delete_token, envelope_community: ec.name)
        delete "/resources/#{id}", payload
        envelope.reload
      end

      it { expect_status(:no_content) }

      it 'marks the envelope as deleted' do
        expect(envelope.deleted_at).not_to be_nil
      end
    end
  end

  context 'with community' do
    let!(:ec)       { create(:envelope_community, name: 'ce_registry', default: true) }
    let!(:name)     { ec.name }
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:resource) { envelope.processed_resource }
    let!(:id)       { resource['@id'] }

    context 'CREATE /:community_name/resources' do
      before do
        post "/#{name}/resources", attributes_for(:envelope, :from_cer)
      end

      it 'returns a 201 Created http status code' do
        expect_status(:created)
      end

      context 'returns the newly created envelope' do
        it { expect_json_types(envelope_id: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '0.52.0') }
      end
    end

    context 'GET /:community_name/resources/:id' do
      let!(:id)       { '123-123-123' }
      let!(:resource) { jwt_encode(attributes_for(:cer_org).merge('@id': id)) }
      let!(:envelope) do
        create(:envelope, :from_cer, :with_cer_credential,
               resource: resource, envelope_community: ec)
      end

      describe 'retrieves the desired resource' do
        before do
          get "/#{name}/resources/#{id}"
        end

        it { expect_status(:ok) }
        it { expect_json('@id': id) }
      end

      context 'wrong community_name' do
        before do
          get "/learning_registry/resources/#{id}"
        end

        it { expect_status(:not_found) }
      end

      context 'invalid id' do
        before do
          get "/#{name}/resources/'9999INVALID'"
        end

        it { expect_status(:not_found) }
      end
    end

    # The default for example.org (testing) is set to 'ce_registry'
    # See config/envelope_communities.json
    context 'envelope_community parameter' do
      describe 'not given' do
        before do
          post '/resources', attributes_for(:envelope, :from_cer)
        end

        describe 'use the default' do
          it { expect_status(:created) }
        end
      end

      describe 'in envelope' do
        before do
          post '/resources', attributes_for(:envelope, :from_cer,
                                            envelope_community: name)
        end

        describe 'use the default' do
          it { expect_status(:created) }
        end

        describe 'don\'t match' do
          let(:name) { 'learning_registry' }
          it { expect_status(:unprocessable_entity) }
          it 'returns the correct error messsage' do
            expect_json('errors.0',
                        ':envelope_community in envelope does not match ' \
                        "the default community (#{ec.name}).")
          end
        end
      end

      describe 'in path' do
        before do
          post '/learning_registry/resources', attributes_for(:envelope)
        end

        it { expect_status(:created) }
      end

      describe 'in path and envelope' do
        let(:url_name) { name }
        before do
          post "/#{url_name}/resources",
               attributes_for(:envelope, :from_cer, envelope_community: name)
        end

        it { expect_status(:created) }

        describe 'don\'t match' do
          let(:url_name) { 'learning_registry' }
          it { expect_status(:unprocessable_entity) }
          it 'returns the correct error messsage' do
            expect_json('errors.0',
                        ':envelope_community in URL and envelope don\'t match.')
          end
        end
      end
    end
  end
end
