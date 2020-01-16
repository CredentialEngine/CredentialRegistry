RSpec.describe API::V1::Publish do
  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }

  let!(:navy) { create(:envelope_community, name: 'navy') }

  describe 'POST /resources/organizations/:organization_id/documents' do
    context 'default community' do
      let(:user) { create(:user) }
      let(:user2) { create(:user) }

      let(:resource_json) do
        File.read(
          MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
        )
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

          post "/resources/organizations/#{organization.id}/documents?skip_validation=true",
               resource_json, 'Authorization' => 'Token ' + user.auth_token.value
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(secondary_publisher_id: nil)
          expect_json(changed: true)
        end
      end

      context 'publish on behalf with two tokens' do
        before do
          organization = create(:organization)
          create(:organization_publisher, organization: organization, publisher: user.publisher)

          post "/resources/organizations/#{organization.id}/documents?skip_validation=true",
               resource_json,
               'Authorization' => 'Token ' + user.auth_token.value,
               'Secondary-Token' => 'Token ' + user2.auth_token.value
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(secondary_publisher_id: user2.publisher.id)
          expect_json(changed: true)
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
          post "/resources/organizations/#{organization.id}/documents?skip_validation=true",
               resource_json, 'Authorization' => token
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(secondary_publisher_id: nil)
          expect_json(changed: true)
        end
      end

      context 'skip_validation' do
        let(:organization) { create(:organization) }
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
        end

        context 'config enabled' do
          it 'skips resource validation when skip_validation=true is provided' do
            # ce/registry has skip_validation enabled
            bad_payload = attributes_for(:cer_org, resource: jwt_encode('@type' => 'ceterms:Badge'))
            bad_payload.delete(:'ceterms:ctid')
            post "/resources/organizations/#{organization.id}/documents",
                 bad_payload.to_json,
                 'Authorization' => 'Token ' + user.auth_token.value
            expect_status(:unprocessable_entity)
            expect_json_keys(:errors)
            expect_json('errors.0', /ceterms:ctid : is required/)

            expect do
              post "/resources/organizations/#{organization.id}/documents?skip_validation=true",
                   attributes_for(:cer_org,
                                  resource: jwt_encode('@type' => 'ceterms:Badge')).to_json,
                   'Authorization' => 'Token ' + user.auth_token.value
            end.to change { Envelope.count }.by(1)
            expect_status(:created)
            expect_json(changed: true)
          end
        end
      end
    end
  end

  describe 'DELETE /resources/organizations/:organization_id/documents/:ctid' do
    context 'default community' do
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

  describe 'PATCH /resources/documents/:ctid/transfer' do
    let(:ctid) { envelope.processed_resource['ceterms:ctid'] }
    let(:current_publisher) { create(:publisher, super_publisher: true) }
    let(:new_organization) { create(:organization) }
    let(:new_organization_id) { new_organization.id }
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }
    let(:original_publisher) { current_publisher }
    let(:user) { create(:user, publisher: current_publisher) }

    let(:envelope) do
      create(
        :envelope,
        envelope_community: community,
        envelope_version: '1.0.0',
        organization_id: organization.id,
        publisher: original_publisher,
        resource: jwt_encode(
          attributes_for(:cer_cred),
          key: organization.key_pair.private_key
        ),
        resource_public_key: organization.key_pair.public_key,
        skip_validation: true
      )
    end

    before do
      create(
        :organization_publisher,
        organization: organization,
        publisher: current_publisher
      )

      if new_organization != organization
        create(
          :organization_publisher,
          organization: new_organization,
          publisher: current_publisher
        )
      end
    end

    context 'default community' do
      let(:community) { ce_registry }

      let(:transfer_ownership) do
        patch "/resources/documents/#{CGI.escape(ctid)}/transfer?organization_id=#{new_organization_id}",
              nil,
              'Authorization' => "Token #{user.auth_token.value}"
      end

      context 'nonexistent envelope' do
        let(:community) { navy }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json('errors.0', 'Envelope not found')
        end
      end

      context 'nonexistent organization' do
        let(:new_organization_id) { 'wtf' }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json(
            'errors.0',
            "Couldn't find Organization with 'id'=#{new_organization_id}"
          )
        end
      end

      context 'user is not a super publisher' do
        let(:current_publisher) { create(:publisher, super_publisher: false) }

        it 'returns 401' do
          transfer_ownership
          expect_status(:unauthorized)
          expect_json(
            'errors.0',
            'Publisher is not authorized to publish on behalf of this organization'
          )
        end
      end

      context 'user is a super publisher' do
        context 'same organization' do
          let(:new_organization) { organization }

          it 'changes nothing' do
            expect {
              transfer_ownership
            }.not_to change { envelope.reload.organization }

            expect {
              transfer_ownership
            }.not_to change { envelope.reload.resource_public_key }

            expect {
              transfer_ownership
            }.not_to change { envelope.reload.envelope_ceterms_ctid }

            expect {
              transfer_ownership
            }.not_to change { envelope.reload.processed_resource }

            expect {
              transfer_ownership
            }.not_to change { envelope.reload.resource }

            expect_status(:ok)
            expect_json(changed: false)
          end
        end

        context 'another organization' do
          it 'transfers ownership' do
            expect {
              transfer_ownership
            }.to change {
              envelope.reload.organization
            }.from(organization).to(new_organization)
            .and(
              change { envelope.reload.resource_public_key }
                .from(organization.key_pair.public_key)
                .to(new_organization.key_pair.public_key)
            )
            .and(not_change { envelope.reload.envelope_ceterms_ctid })
            .and(not_change { envelope.reload.processed_resource })

            expect_status(:ok)
            expect_json(changed: true)
          end
        end
      end
    end

    context 'explicit community' do
      let(:community) { navy }

      let(:transfer_ownership) do
        path = '/navy/resources/documents' \
               "/#{CGI.escape(envelope.envelope_ceterms_ctid)}" \
               "/transfer?organization_id=#{new_organization_id}"

        patch path, nil, 'Authorization' => "Token #{user.auth_token.value}"
      end

      context 'nonexistent envelope' do
        let(:community) { ce_registry }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json('errors.0', 'Envelope not found')
        end
      end

      context 'nonexistent organization' do
        let(:new_organization_id) { 'wtf' }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json(
            'errors.0',
            "Couldn't find Organization with 'id'=#{new_organization_id}"
          )
        end
      end

      context 'user is not a super publisher' do
        let(:current_publisher) { create(:publisher, super_publisher: false) }

        it 'returns 401' do
          transfer_ownership
          expect_status(:unauthorized)
          expect_json(
            'errors.0',
            'Publisher is not authorized to publish on behalf of this organization'
          )
        end
      end

      context 'user is a super publisher' do
        context 'same publisher' do
          context 'same organization' do
            let(:new_organization) { organization }

            it 'changes nothing' do
              expect {
                transfer_ownership
              }.not_to change { envelope.reload.organization }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.publisher }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.resource_public_key }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.envelope_ceterms_ctid }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.processed_resource }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.resource }

              expect_status(:ok)
              expect_json(changed: false)
            end
          end

          context 'another organization' do
            it 'transfers ownership' do
              expect {
                transfer_ownership
              }.to change {
                envelope.reload.organization
              }.from(organization).to(new_organization)
              .and(
                change { envelope.reload.resource_public_key }
                  .from(organization.key_pair.public_key)
                  .to(new_organization.key_pair.public_key)
              )
              .and(not_change { envelope.reload.envelope_ceterms_ctid })
              .and(not_change { envelope.reload.processed_resource })
              .and(not_change { envelope.reload.publisher })

              expect_status(:ok)
              expect_json(changed: true)
            end
          end
        end
        
        context 'another publisher' do
          let(:original_publisher) { create(:publisher) }

          context 'same organization' do
            let(:new_organization) { organization }

            it 'changes publisher only' do
              expect {
                transfer_ownership
              }.to change {
                envelope.reload.publisher
              }.from(original_publisher).to(current_publisher)

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.organization }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.resource_public_key }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.envelope_ceterms_ctid }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.processed_resource }

              expect {
                transfer_ownership
              }.not_to change { envelope.reload.resource }

              expect_status(:ok)
              expect_json(changed: true)
            end
          end

          context 'another organization' do
            it 'transfers ownership' do
              expect {
                transfer_ownership
              }.to change {
                envelope.reload.organization
              }.from(organization).to(new_organization)
              .and(
                change { envelope.reload.resource_public_key }
                  .from(organization.key_pair.public_key)
                  .to(new_organization.key_pair.public_key)
              )
              .and(
                change {
                  envelope.reload.publisher
                }.from(original_publisher).to(current_publisher)
              )
              .and(not_change { envelope.reload.envelope_ceterms_ctid })
              .and(not_change { envelope.reload.processed_resource })

              expect_status(:ok)
              expect_json(changed: true)
            end
          end
        end
      end
    end
  end
end
