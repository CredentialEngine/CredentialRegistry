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
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '0.52.0') }
      end
    end

    context 'publish on behalf without token' do
      before do
        organization = create(:organization)

        post "/resources/organizations/#{organization.id}/documents",
             resource_json
      end

      it 'returns a 401 unauthorized http status code' do
        expect_status(:unauthorized)
      end
    end

    context 'publish on behalf with token, can publish on behalf of organization' do
      before do
        organization = create(:organization)
        create(:organization_publisher, organization: organization, publisher: user.publisher)

        post "/resources/organizations/#{organization.id}/documents",
             resource_json, 'Authorization' => 'Token ' + user.auth_token.value
      end

      it 'returns a 201 created http status code' do
        expect_status(:created)
      end

      context 'returns the newly created envelope' do
        it { expect_json_types(envelope_id: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '1.0.0') }
      end
    end

    context 'publish on behalf with two tokens' do
      before do
        organization = create(:organization)
        create(:organization_publisher, organization: organization, publisher: user.publisher)

        post "/resources/organizations/#{organization.id}/documents",
             resource_json,
             'Authorization' => 'Token ' + user.auth_token.value,
             'Secondary-Token' => 'Token ' + user2.auth_token.value
      end

      it 'returns a 201 created http status code' do
        expect_status(:created)
      end

      context 'returns the newly created envelope' do
        it { expect_json_types(envelope_id: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '1.0.0') }
        it { expect_json(secondary_publisher_id: user2.publisher.id) }
      end
    end

    context 'publish on behalf with token, can\'t publish on behalf of the organization' do
      before do
        organization = create(:organization)

        post "/resources/organizations/#{organization.id}/documents",
             resource_json, 'Authorization' => 'Token ' + user.auth_tokens.first.value
      end

      it 'returns a 401 unauthorized http status code' do
        expect_status(:unauthorized)
      end
    end

    context 'publish on behalf with token, super publisher' do
      before do
        super_publisher = create(:publisher, super_publisher: true)
        super_publisher_user = create(:user, publisher: super_publisher)

        organization = create(:organization)

        token = "Token #{super_publisher_user.auth_tokens.first.value}"
        post "/resources/organizations/#{organization.id}/documents",
             resource_json, 'Authorization' => token
      end

      it 'returns a 201 created http status code' do
        expect_status(:created)
      end

      context 'returns the newly created envelope' do
        it { expect_json_types(envelope_id: :string) }
        it { expect_json(envelope_community: 'ce_registry') }
        it { expect_json(envelope_version: '1.0.0') }
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

    context 'GET /resources/:id' do
      let(:ctid) { Faker::Lorem.characters(10) }
      let(:default_id) { Faker::Lorem.characters(10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{default_id}"
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
          resource: jwt_encode(resource_with_ids)
        )

        get "/resources/#{CGI.escape(id)}"
      end

      context 'without `id_field`' do
        context 'by custom ID' do
          let(:id) { ctid }

          it 'retrieves nothing' do
            expect_status(:not_found)
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
          let(:id) { default_id }

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

        context 'by full ID' do
          let(:id) { full_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end

        context 'by short ID' do
          let(:id) { default_id }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
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
