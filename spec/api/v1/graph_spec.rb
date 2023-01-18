RSpec.describe API::V1::Graph do
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

    context 'GET /graph/:id' do
      let(:ctid) { Faker::Lorem.characters(number: 10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{ctid}"
      end
      let(:id_field) { nil }
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

        get "/graph/#{CGI.escape(id).upcase}"
      end

      context 'without `id_field`' do
        context 'by short ID' do
          let(:id) { ctid }

          it 'retrieves the desired resource by looking at the prefix' do
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

          context 'upcase' do
            let(:id) { competency_id.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:'@graph')
              expect(json_body[:'@graph'].map { |o| o[:'ceterms:ctid'] }).to include(competency_id)
            end
          end

          context 'downcase' do
            let(:id) { competency_id.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:'@graph')
              expect(json_body[:'@graph'].map { |o| o[:'ceterms:ctid'] }).to include(competency_id)
            end
          end
        end

        context 'by primary ID' do
          context 'upcase' do
            let(:id) { ctid.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:'@graph')
            end
          end

          context 'downcase' do
            let(:id) { ctid.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:'@graph')
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

    context 'POST /graph/search' do
      let!(:envelope1) do
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do
        create(:envelope, :with_cer_credential, envelope_community: ec, skip_validation: true)
      end

      let!(:envelope3) do
        create(:envelope, :with_cer_credential, skip_validation: true)
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
        expect(JSON(response.body)).to match_array(
          [envelope1.processed_resource, envelope2.processed_resource]
        )
      end
    end
  end

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

    context 'GET /:community_name/graph/:id' do
      let!(:id)       { '123-123-123' }
      let!(:resource) { jwt_encode(attributes_for(:cer_org).merge('@id': id)) }
      let!(:envelope) do
        create(:envelope, :from_cer, :with_cer_credential,
               resource: resource, envelope_community: ec)
      end

      context 'public community' do
        let(:secured) { false }

        before do
          expect(ValidateApiKey).not_to receive(:call)
        end

        describe 'retrieves the desired resource' do
          before do
            get "/#{name}/graph/#{id}"
          end

          it { expect_status(:ok) }
          it { expect_json('@id': id) }
        end

        context 'wrong community_name' do
          before do
            get "/learning_registry/graph/#{id}"
          end

          it { expect_status(:not_found) }
        end

        context 'invalid id' do
          before do
            get "/#{name}/graph/'9999INVALID'"
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
            .and_return(api_key_validation_result)
        end

        context 'authenticated' do
          let(:api_key_validation_result) { true }

          describe 'retrieves the desired resource' do
            before do
              get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:ok) }
            it { expect_json('@id': id) }
          end

          context 'invalid id' do
            before do
              get "/#{name}/graph/'9999INVALID'",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:not_found) }
          end
        end

        context 'unauthenticated' do
          let(:api_key_validation_result) { false }

          before do
            get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
      end
    end

    context 'POST /:community_name/graph/search' do
      let!(:envelope1) do
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do
        create(:envelope, :with_cer_credential, envelope_community: ec, skip_validation: true)
      end

      let!(:envelope3) do
        create(:envelope, :with_cer_credential, skip_validation: true)
      end

      context 'public community' do
        let(:secured) { false }

        before do
          expect(ValidateApiKey).not_to receive(:call)

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
          expect(JSON(response.body)).to match_array(
            [envelope1.processed_resource, envelope2.processed_resource]
          )
        end
      end

      context 'secured community' do
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          expect(ValidateApiKey).to receive(:call)
            .with(api_key, ec)
            .and_return(api_key_validation_result)
        end

        context 'authenticated' do
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
            expect(JSON(response.body)).to match_array(
              [envelope1.processed_resource, envelope2.processed_resource]
            )
          end
        end

        context 'unauthenticated' do
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
      end
    end
  end
end
