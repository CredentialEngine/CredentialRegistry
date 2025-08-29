RSpec.describe API::V1::Graph do
  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
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

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /graph/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctid) { Faker::Lorem.characters(number: 10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{ctid}"
      end
      let(:id_field) { nil }
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
          resource: jwt_encode(resource_with_ids)
        )

        get "/graph/#{CGI.escape(id).upcase}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without `id_field`' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by short ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource by looking at the prefix' do
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

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { competency_id.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
              expect(json_body[:@graph].map { |o| o[:'ceterms:ctid'] }).to include(competency_id)
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
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
              expect(json_body[:@graph].map { |o| o[:'ceterms:ctid'] }).to include(competency_id)
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
              expect(json_body).to have_key(:@graph)
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
              expect(json_body).to have_key(:@graph)
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
    context 'POST /graph/search' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential)
      end

      before do
        post '/graph/search',
             {
               ctids: [
                 envelope1.envelope_ceterms_ctid.upcase,
                 envelope2.envelope_ceterms_ctid.upcase,
                 envelope3.envelope_ceterms_ctid.upcase
               ]
             }
      end

      it 'fetches graphs with the given CTIDs' do
        expect_status(:ok)
        expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                       envelope2.processed_resource)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'with community' do
    let!(:name) { ec.name }

    let(:ec) do
      create(
        :envelope_community,
        default: true,
        name: 'ce_registry',
        secured: secured
      )
    end

    context 'GET /:community_name/graph/:id' do # rubocop:todo RSpec/ContextWording
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

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).not_to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
        end

        # rubocop:todo RSpec/NestedGroups
        describe 'retrieves the desired resource' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/graph/#{id}"
          end

          it { expect_status(:ok) }
          it { expect_json('@id': id) }
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'wrong community_name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/learning_registry/graph/#{id}"
          end

          it { expect_status(:not_found) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/graph/'9999INVALID'"
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
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
            # rubocop:enable RSpec/MessageSpies
            # rubocop:enable RSpec/StubbedMock
            .with(api_key, ec)
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
              get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:ok) }
            it { expect_json('@id': id) }
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            before do
              get "/#{name}/graph/'9999INVALID'",
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
            get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    context 'POST /:community_name/graph/search' do # rubocop:todo RSpec/ContextWording
      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'public community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:secured) { false }

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).not_to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies

          post '/ce_registry/graph/search',
               {
                 ctids: [
                   envelope1.envelope_ceterms_ctid,
                   envelope2.envelope_ceterms_ctid,
                   envelope3.envelope_ceterms_ctid
                 ]
               }
        end

        it 'fetches graphs with the given CTIDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                         envelope2.processed_resource)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'secured community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
            # rubocop:enable RSpec/MessageSpies
            # rubocop:enable RSpec/StubbedMock
            .with(api_key, ec)
            .and_return(api_key_validation_result)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { true }

          before do
            post '/ce_registry/graph/search',
                 {
                   ctids: [
                     envelope1.envelope_ceterms_ctid,
                     envelope2.envelope_ceterms_ctid,
                     envelope3.envelope_ceterms_ctid
                   ]
                 },
                 'Authorization' => "Token #{api_key}"
          end

          it 'fetches graphs with the given CTIDs' do
            expect_status(:ok)
            expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                           envelope2.processed_resource)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { false }

          before do
            post '/ce_registry/graph/search',
                 {
                   ctids: [
                     envelope1.envelope_ceterms_ctid,
                     envelope2.envelope_ceterms_ctid,
                     envelope3.envelope_ceterms_ctid
                   ]
                 },
                 'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end
end
