RSpec.describe API::V1::Resources do
  context 'default community' do
    let!(:ec)       { create(:envelope_community, name: 'ce_registry') }
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:navy)     { create(:envelope_community, name: 'navy') }
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
      let(:ctid) { Faker::Lorem.characters(number: 10) }
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

        get "/resources/#{CGI.escape(id).upcase}"
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
      let(:now) { Faker::Time.backward(days: 7).in_time_zone.change(usec: 0) }

      before(:each) do
        payload = attributes_for(:delete_token, envelope_community: ec.name)

        travel_to now do
          delete "/resources/#{id}", payload
        end

        envelope.reload
      end

      it { expect_status(:no_content) }

      it 'marks the envelope as deleted' do
        expect(envelope.deleted_at).to eq(now)
        expect(envelope.envelope_resources.first.deleted_at).to eq(now)
      end
    end

    context 'POST /resources/search' do
      let(:bnodes) {}
      let(:bnode1) { "_:#{Envelope.generate_ctid}" }
      let(:bnode2) { "_:#{Envelope.generate_ctid}" }
      let(:bnode3) { "_:#{Envelope.generate_ctid}" }
      let(:ctid1) { Faker::Lorem.characters(number: 32) }
      let(:ctid2) { Faker::Lorem.characters(number: 32) }
      let(:ctid3) { Faker::Lorem.characters(number: 32) }
      let(:ctids) {}

      let(:resource1) do
        attributes_for(:cer_competency_framework, ctid: ctid1)
          .except(:id)
          .stringify_keys
      end

      let(:resource2) { attributes_for(:cer_competency) }

      let(:resource3) do
        attributes_for(:cer_ass_prof_bnode, :@id => bnode1).stringify_keys
      end

      let(:resource4) do
        attributes_for(:cer_competency_framework, ctid: ctid2)
          .except(:id)
          .stringify_keys
      end

      let(:resource5) { attributes_for(:cer_competency) }

      let(:resource6) do
        attributes_for(:cer_ass_prof_bnode, :@id => bnode2).stringify_keys
      end

      let!(:envelope1) do
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(
            attributes_for(:cer_graph_competency_framework).merge(
              :@graph => [resource1, resource2, resource3]
            )
          ),
          skip_validation: true
        )
      end

      let!(:envelope2) do
        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(
            attributes_for(:cer_graph_competency_framework).merge(
              :@graph => [resource4, resource5, resource6]
            )
          ),
          skip_validation: true
        )
      end

      before do
        post '/resources/search', { bnodes: bnodes, ctids: ctids }
      end

      context 'by CTIDs' do
        let(:ctids) { [ctid1, ctid2, ctid3] }

        it 'returns payloads with the given CTIDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to match_array([resource1, resource4])
        end
      end

      context 'by bnode IDs' do
        let(:bnodes) { [bnode1, bnode2, bnode3] }

        it 'returns payloads with the given bnode IDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to match_array([resource3, resource6])
        end
      end

      context 'by both' do
        let(:ctids) { [ctid1, ctid3] }
        let(:bnodes) { [bnode2] }

        it 'returns payloads with the given CTIDs or bnode IDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to match_array([resource1, resource6])
        end
      end
    end

    context 'POST /resources/check_existence' do
      let(:ctid1) { Faker::Lorem.characters(number: 32) }
      let(:ctid2) { Faker::Lorem.characters(number: 32) }
      let(:ctid3) { Faker::Lorem.characters(number: 32) }

      before do
        resource1 = attributes_for(:cer_competency_framework, ctid: ctid1)
          .except(:id)
          .stringify_keys

        resource2 = attributes_for(:cer_competency_framework, ctid: ctid2)
          .except(:id)
          .stringify_keys

        resource3 = attributes_for(:cer_competency_framework, ctid: ctid3)
          .except(:id)
          .stringify_keys

        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(
            attributes_for(:cer_graph_competency_framework)
              .merge(:@graph => [resource1])
          ),
          skip_validation: true
        )

        create(
          :envelope,
          :from_cer,
          resource: jwt_encode(
            attributes_for(:cer_graph_competency_framework)
              .merge(:@graph => [resource2])
          ),
          skip_validation: true
        ).touch(:deleted_at)

        create(
          :envelope,
          envelope_community: navy,
          resource: jwt_encode(
            attributes_for(:cer_graph_competency_framework)
              .merge(:@graph => [resource3])
          ),
          skip_validation: true
        )
      end

      it 'returns existing CTIDs' do
        post '/resources/check_existence', { ctids: [ctid1, ctid2, ctid3] }
        expect_status(:ok)
        expect(JSON(response.body)).to match_array([ctid1])
      end
    end
  end

  context 'with community' do
    let(:secured)   { [false, true].sample }
    let!(:ec)       { create(:envelope_community, name: 'ce_registry', default: true, secured: secured) }
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

      context 'public community' do
        let(:secured) { false }

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

      context 'secured community' do
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          expect(ValidateApiKey).to receive(:call)
            .with(api_key, ec)
            .at_least(1).times
            .and_return(api_key_validation_result)
        end

        context 'authenticated' do
          let(:api_key_validation_result) { true }

          describe 'retrieves the desired resource' do
            before do
              get "/#{name}/resources/#{id}",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:ok) }
            it { expect_json('@id': id) }
          end

          context 'invalid id' do
            before do
              get "/#{name}/resources/'9999INVALID'",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:not_found) }
          end
        end

        context 'unauthenticated' do
          let(:api_key_validation_result) { false }

          before do
            get "/#{name}/resources/#{id}",
                'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
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
