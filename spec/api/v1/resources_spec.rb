RSpec.describe API::V1::Resources do
  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
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

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'CREATE /resources' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        post '/resources', attributes_for(:envelope, :from_cer,
                                          envelope_community: ec.name)
      end

      it 'returns a 201 Created http status code' do
        expect_status(:created)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'returns the newly created envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it { expect_json_types(envelope_id: :string) }
        it { expect_json_types(envelope_ceterms_ctid: :string) }
        it { expect_json_types(envelope_ctdl_type: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '0.52.0') }
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'CREATE /resources to update' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        update  = jwt_encode(resource.merge('ceterms:name': 'Updated'))
        payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                                 resource: update,
                                 envelope_community: ec.name)
        post '/resources', payload
        envelope.reload
      end

      it { expect_status(:ok) }

      it 'updates some data inside the resource' do
        expect(envelope.processed_resource['ceterms:name']).to eq('Updated')
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    # rubocop:todo RSpec/ContextWording
    context 'CREATE /resources to update - updates for graph URL' do
      # rubocop:enable RSpec/ContextWording
      before do
        update = jwt_encode(
          resource.merge(
            'ceterms:name': 'Updated',
            '@id': resource['@id'].gsub('/resources', '/graph')
          )
        )
        payload = attributes_for(:envelope, :from_cer, :with_cer_credential,
                                 resource: update,
                                 envelope_community: ec.name)
        post '/resources', payload
        envelope.reload
      end

      it { expect_status(:unprocessable_entity) }

      it { expect_json('errors', ['Resource CTID must be unique']) }
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /resources/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctid) { Faker::Lorem.characters(number: 10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{ctid}"
      end
      let(:id_field) {} # rubocop:todo Lint/EmptyBlock
      let(:resource_with_ids) do
        resource.merge('@id' => full_id, 'ceterms:ctid' => ctid)
      end

      before do
        allow_any_instance_of(EnvelopeCommunity) # rubocop:todo RSpec/AnyInstance
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

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id) { Faker::Lorem.characters(number: 11) }

        it 'cannot retrieve the desired resource' do
          expect_status(:not_found)
          expect_json(errors: ["Couldn't find Resource"])
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/NestedGroups
      context 'without `id_field`' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by full ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { full_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by short ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with `id_field`' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id_field) { 'ceterms:ctid' }

        # rubocop:todo RSpec/RepeatedExampleGroupBody
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/RepeatedExampleGroupBody

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID, downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid.downcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID, upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid.upcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by full ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { full_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/RepeatedExampleGroupBody
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by short ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/RepeatedExampleGroupBody
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with graph resources' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id_field) { 'ceterms:ctid' }
        let(:resource_with_ids) do
          attributes_for(:cer_graph_competency_framework, ctid: ctid)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by ID internal to the graph' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:competency_id) do
            resource_with_ids[:@graph]
              .find { |obj| obj[:@type] == 'ceasn:Competency' }[:'ceterms:ctid']
          end
          let(:full_competency_id) do
            "http://credentialengineregistry.org/resources/#{competency_id}"
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { competency_id.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_competency_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { competency_id.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_competency_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by primary ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { ctid.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { ctid.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect_json('@context': 'http://credreg.net/ctdlasn/schema/context/json')
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by bnode ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) do
            resource_with_ids[:@graph]
              .find { |obj| obj[:@id].start_with?('_') }[:'ceterms:ctid']
          end

          it 'cannot retrieve the desired resource' do
            expect_status(:not_found)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'PUT /resources/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
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
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'DELETE /resources/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        payload = attributes_for(:delete_token, envelope_community: ec.name)
        delete "/resources/#{id}", payload
        envelope.reload
      end

      it { expect_status(:no_content) }

      it 'marks the envelope as deleted' do
        expect(envelope.deleted_at).not_to be_nil
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'POST /resources/search' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:bnodes) {} # rubocop:todo Lint/EmptyBlock
      let(:bnode1) { "_:#{Envelope.generate_ctid}" } # rubocop:todo RSpec/IndexedLet
      let(:bnode2) { "_:#{Envelope.generate_ctid}" } # rubocop:todo RSpec/IndexedLet
      let(:bnode3) { "_:#{Envelope.generate_ctid}" } # rubocop:todo RSpec/IndexedLet
      let(:ctid1) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet
      let(:ctid2) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet
      let(:ctid3) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet
      let(:ctids) {} # rubocop:todo Lint/EmptyBlock

      let(:resource1) do # rubocop:todo RSpec/IndexedLet
        attributes_for(:cer_competency_framework, ctid: ctid1)
          .except(:id)
          .stringify_keys
      end

      let(:resource2) { attributes_for(:cer_competency) } # rubocop:todo RSpec/IndexedLet

      let(:resource3) do # rubocop:todo RSpec/IndexedLet
        attributes_for(:cer_ass_prof_bnode, :@id => bnode1).stringify_keys
      end

      let(:resource4) do # rubocop:todo RSpec/IndexedLet
        attributes_for(:cer_competency_framework, ctid: ctid2)
          .except(:id)
          .stringify_keys
      end

      let(:resource5) { attributes_for(:cer_competency) } # rubocop:todo RSpec/IndexedLet

      let(:resource6) do # rubocop:todo RSpec/IndexedLet
        attributes_for(:cer_ass_prof_bnode, :@id => bnode2).stringify_keys
      end

      # rubocop:todo RSpec/LetSetup
      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet, RSpec/LetSetup
        # rubocop:enable RSpec/LetSetup
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

      # rubocop:todo RSpec/LetSetup
      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet, RSpec/LetSetup
        # rubocop:enable RSpec/LetSetup
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

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'by CTIDs' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:ctids) { [ctid1, ctid2, ctid3] }

        it 'returns payloads with the given CTIDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to contain_exactly(resource1, resource4)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'by bnode IDs' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:bnodes) { [bnode1, bnode2, bnode3] }

        it 'returns payloads with the given bnode IDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to contain_exactly(resource3, resource6)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'by both' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:ctids) { [ctid1, ctid3] }
        let(:bnodes) { [bnode2] }

        it 'returns payloads with the given CTIDs or bnode IDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to contain_exactly(resource1, resource6)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'POST /resources/check_existence' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctid1) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet
      let(:ctid2) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet
      let(:ctid3) { Faker::Lorem.characters(number: 32) } # rubocop:todo RSpec/IndexedLet

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
        expect(JSON(response.body)).to contain_exactly(ctid1)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'with community' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:secured)   { [false, true].sample }
    let!(:ec)       do
      create(:envelope_community, name: 'ce_registry', default: true, secured: secured)
    end
    let!(:name)     { ec.name }
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let!(:resource) { envelope.processed_resource }
    let!(:id)       { resource['@id'] }

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'CREATE /:community_name/resources' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        post "/#{name}/resources", attributes_for(:envelope, :from_cer)
      end

      it 'returns a 201 Created http status code' do
        expect_status(:created)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'returns the newly created envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it { expect_json_types(envelope_id: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '0.52.0') }
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /:community_name/resources/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let!(:id)       { '123-123-123' }
      let!(:resource) { jwt_encode(attributes_for(:cer_org).merge('@id': id)) }
      let!(:envelope) do # rubocop:todo RSpec/LetSetup
        create(:envelope, :from_cer, :with_cer_credential,
               resource: resource, envelope_community: ec)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'public community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:secured) { false }

        # rubocop:todo RSpec/NestedGroups
        describe 'retrieves the desired resource' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/resources/#{id}"
          end

          it { expect_status(:ok) }
          it { expect_json('@id': id) }
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'wrong community_name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/learning_registry/resources/#{id}"
          end

          it { expect_status(:not_found) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/resources/'9999INVALID'"
          end

          it { expect_status(:not_found) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'secured community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
            # rubocop:enable RSpec/MessageSpies
            .with(api_key, ec)
            .at_least(:once)
            .and_return(api_key_validation_result)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { true }

          # rubocop:todo RSpec/NestedGroups
          describe 'retrieves the desired resource' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            before do
              get "/#{name}/resources/#{id}",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:ok) }
            it { expect_json('@id': id) }
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            before do
              get "/#{name}/resources/'9999INVALID'",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:not_found) }
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { false }

          before do
            get "/#{name}/resources/#{id}",
                'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # The default for example.org (testing) is set to 'ce_registry'
    # See config/envelope_communities.json
    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'envelope_community parameter' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      describe 'not given' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          post '/resources', attributes_for(:envelope, :from_cer)
        end

        # rubocop:todo RSpec/NestedGroups
        describe 'use the default' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it { expect_status(:created) }
        end
      end

      # rubocop:todo RSpec/NestedGroups
      describe 'in envelope' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          post '/resources', attributes_for(:envelope, :from_cer,
                                            envelope_community: name)
        end

        # rubocop:todo RSpec/NestedGroups
        describe 'use the default' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it { expect_status(:created) }
        end

        # rubocop:todo RSpec/NestedGroups
        describe 'don\'t match' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:name) { 'learning_registry' }

          it { expect_status(:unprocessable_entity) }

          it 'returns the correct error messsage' do
            expect_json('errors.0',
                        ':envelope_community in envelope does not match ' \
                        "the default community (#{ec.name}).")
          end
        end
      end

      # rubocop:todo RSpec/NestedGroups
      describe 'in path' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          post '/learning_registry/resources', attributes_for(:envelope)
        end

        it { expect_status(:created) }
      end

      # rubocop:todo RSpec/NestedGroups
      describe 'in path and envelope' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:url_name) { name }

        before do
          post "/#{url_name}/resources",
               attributes_for(:envelope, :from_cer, envelope_community: name)
        end

        it { expect_status(:created) }

        # rubocop:todo RSpec/NestedGroups
        describe 'don\'t match' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:url_name) { 'learning_registry' }

          it { expect_status(:unprocessable_entity) }

          it 'returns the correct error messsage' do
            expect_json('errors.0',
                        ':envelope_community in URL and envelope don\'t match.')
          end
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
