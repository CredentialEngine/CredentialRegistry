describe API::V1::Publish do
  context 'default community' do
    let!(:ec) { create(:envelope_community, name: 'ce_registry') }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:resource_json) do
      content = File.read MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
      JSON.parse(content).first.to_json
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
        it { expect_json_types(envelope_ceterms_ctid: :string) }
        it { expect_json_types(envelope_ctdl_type: :string) }
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

    context 'delete envelope published on behalf, can publish on behalf of organization' do
      before do
        publisher = create(:publisher)
        user = create(:user, publisher: publisher)
        organization = create(:organization)
        create(:organization_publisher, organization: organization, publisher: publisher)

        envelope = create(:envelope,
                          :from_cer,
                          :with_cer_credential,
                          publisher_id: publisher.id,
                          organization_id: organization.id)

        ctid = envelope.processed_resource['ceterms:ctid']

        token = "Token #{user.auth_token.value}"
        delete "/resources/organizations/#{organization.id}/documents/#{CGI.escape(ctid)}",
               nil,
               'Authorization' => token
      end

      it 'deletes the envelope' do
        expect(Envelope.not_deleted.count).to eq(0)
        expect_status(:no_content)
      end
    end

    context 'delete envelope published on behalf, can\'t publish on behalf of organization' do
      before do
        publisher = create(:publisher)
        user = create(:user, publisher: publisher)
        organization = create(:organization)

        envelope = create(:envelope,
                          :from_cer,
                          :with_cer_credential,
                          publisher_id: publisher.id,
                          organization_id: organization.id)

        ctid = envelope.processed_resource['ceterms:ctid']

        token = "Token #{user.auth_token.value}"
        delete "/resources/organizations/#{organization.id}/documents/#{CGI.escape(ctid)}",
               nil,
               'Authorization' => token
      end

      it 'returns 401 unauthorized and does not delete the envelope' do
        expect(Envelope.count).to eq(1)
        expect_status(:unauthorized)
      end
    end

    context 'delete nonexistent envelope' do
      before do
        publisher = create(:publisher)
        user = create(:user, publisher: publisher)
        organization = create(:organization)
        create(:organization_publisher, organization: organization, publisher: publisher)

        create(:envelope,
               :from_cer,
               :with_cer_credential,
               publisher_id: publisher.id,
               organization_id: organization.id)

        token = "Token #{user.auth_token.value}"
        delete "/resources/organizations/#{organization.id}/documents/dummy_ctid",
               nil,
               'Authorization' => token
      end

      it 'returns 404 not found' do
        expect(Envelope.count).to eq(1)
        expect_status(:not_found)
      end
    end
  end
end
