RSpec.describe API::V1::Publish do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:now) { Faker::Time.backward(days: 7).in_time_zone.change(usec: 0) }
  let(:organization) { create(:organization) }

  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let!(:navy) { create(:envelope_community, name: 'navy') }

  describe 'POST /resources/organizations/:organization_id/documents' do
    let(:publishing_organization) { create(:organization) }

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
          post "/resources/organizations/#{organization._ctid}/documents",
               resource_json
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end

      context 'publish on behalf with token, can publish on behalf of organization' do
        let(:updated_resource_json) do
          resource = JSON(resource_json)
          resource['@graph'][0]['new_property'] = Faker::Lorem.sentence
          resource.to_json
        end

        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          # New envelope
          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                  resource_json, 'Authorization' => 'Token ' + user.auth_token.value
          end

          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: true)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: now.to_date.to_s)
          expect_json(secondary_publisher_id: nil)

          # Existing envelope, same payload
          post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                  resource_json, 'Authorization' => 'Token ' + user.auth_token.value

          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: false)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: now.to_date.to_s)
          expect_json(secondary_publisher_id: nil)

          # Existing envelope, different payload
          travel_to now + 1.day do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                  updated_resource_json, 'Authorization' => 'Token ' + user.auth_token.value
          end

          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: true)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: (now + 1.day).to_date.to_s)
          expect_json(secondary_publisher_id: nil)
        end
      end

      context 'publish on behalf with two tokens' do
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)

          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                 resource_json,
                 'Authorization' => 'Token ' + user.auth_token.value,
                 'Secondary-Token' => 'Token ' + user2.auth_token.value
          end
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: true)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: now.to_date.to_s)
          expect_json(secondary_publisher_id: user2.publisher.id)
        end
      end

      context 'publish on behalf with token, can\'t publish on behalf of the organization' do
        before do
          post "/resources/organizations/#{organization._ctid}/documents",
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
          token = "Token #{super_publisher_user.auth_tokens.first.value}"

          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                 resource_json, 'Authorization' => token
          end
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: true)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: now.to_date.to_s)
          expect_json(secondary_publisher_id: nil)
        end
      end

      context 'skip_validation' do
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
        end

        context 'config enabled' do
          it 'skips resource validation when skip_validation=true is provided' do
            # ce/registry has skip_validation enabled
            bad_payload = attributes_for(:cer_org, resource: jwt_encode({ '@type' => 'ceterms:Badge' }))
            bad_payload.delete(:'ceterms:ctid')
            post "/resources/organizations/#{organization._ctid}/documents",
                  bad_payload.to_json,
                  'Authorization' => 'Token ' + user.auth_token.value
            expect_status(:unprocessable_entity)
            expect_json_keys(:errors)
            expect_json('errors.0', /ceterms:ctid : is required/)

            expect do
              travel_to now do
                post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                     attributes_for(:cer_org,
                                    resource: jwt_encode({ '@type' => 'ceterms:Badge' })).to_json,
                     'Authorization' => 'Token ' + user.auth_token.value
              end
            end.to change { Envelope.count }.by(1)
            expect_status(:created)
            expect_json(changed: true)
            expect_json(last_verified_on: now.to_date.to_s)
          end
        end
      end

      context 'republish under another organization' do
        let(:organization) { create(:organization) }
        let(:publisher) { user.publisher }

        let(:envelope) do
          create(
            :envelope,
            :from_cer,
            :with_cer_credential,
            publisher: publisher,
            organization: create(:organization)
          )
        end

        before do
          create(
            :organization_publisher,
            organization: organization,
            publisher: user.publisher
          )
        end

        it 'returns a 422 Unprocessable Entity' do
          post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
               envelope.processed_resource.to_json,
               'Authorization' => user.auth_token.value

          expect_status(:unprocessable_entity)
          expect_json_keys(:errors)
          expect_json('errors.0', /Resource CTID must be unique/)
        end
      end

      context 'publish on behalf with token, can access the publishing organization' do
        before do
          create(
            :organization_publisher,
            organization: organization,
            publisher: user.publisher
          )

          create(
            :organization_publisher,
            organization: publishing_organization,
            publisher: user.publisher
          )

          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?" \
                 "published_by=#{publishing_organization._ctid}&" \
                 'skip_validation=true',
                 resource_json,
                 'Authorization' => 'Token ' + user.auth_token.value
          end
        end

        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          expect_status(:created)
          expect_json_types(envelope_id: :string)
          expect_json(changed: true)
          expect_json(envelope_ceterms_ctid: 'ce-53bc7e5d-d39c-4687-ac89-0474f691055d')
          expect_json(envelope_ctdl_type: 'ceterms:MasterDegree')
          expect_json(envelope_community: 'ce_registry')
          expect_json(envelope_version: '1.0.0')
          expect_json(last_verified_on: now.to_date.to_s)
          expect_json(owned_by: organization._ctid)
          expect_json(published_by: publishing_organization._ctid)
          expect_json(secondary_publisher_id: nil)

          envelope = Envelope.last
          expect(envelope.publishing_organization).to eq(publishing_organization)
        end
      end

      context "publish on behalf with token, can't access the publishing organization" do
        before do
          create(
            :organization_publisher,
            organization: organization,
            publisher: user.publisher
          )

          post "/resources/organizations/#{organization._ctid}/documents?" \
               "published_by=#{publishing_organization._ctid}&" \
               'skip_validation=true',
               resource_json,
               'Authorization' => 'Token ' + user.auth_token.value
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end
    end
  end

  describe 'DELETE /resources/documents/:ctid' do
    let(:auth_token) { user.auth_token.value }
    let(:envelope_resource) { envelope.envelope_resources.first }
    let(:publisher) { create(:publisher) }
    let(:purge) {}
    let(:user) { create(:user, publisher: publisher) }

    let!(:envelope) do
      create(
        :envelope,
        :with_cer_credential,
        envelope_community: community,
        organization: organization
      )
    end

    context 'default community' do
      let(:community) { ce_registry }

      let(:delete_envelope) do
        travel_to now do
          delete "/resources/documents/#{CGI.escape(ctid)}?purge=#{purge}",
                 nil,
                 'Authorization' => "Token #{auth_token}"
        end
      end

      context 'invalid token' do
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          delete_envelope
          expect_status(:unauthorized)
        end
      end

      context 'soft deletion' do
        let(:purge) { [nil, 0, 'no', false].sample }

        context 'nonexistent envelope' do
          let(:community) { navy }

          it 'returns 404 not found' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:not_found)
          end
        end

        context 'unauthorized publisher' do
          it 'returns 401 unauthorized and does not delete the envelope' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:unauthorized)
          end
        end

        context 'authorized publisher' do
          before do
            create(
              :organization_publisher,
              organization: organization,
              publisher: publisher
            )
          end

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and not_change { envelope.reload.purged_at }

            expect_status(:no_content)
          end
        end

        context 'super publisher' do
          let(:organization) {}
          let(:publisher) { create(:publisher, super_publisher: true) }

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and not_change { envelope.reload.purged_at }

            expect_status(:no_content)
          end
        end
      end

      context 'physical deletion' do
        let(:purge) { [1, 'yes', true].sample }

        context 'nonexistent envelope' do
          let(:community) { navy }

          it 'returns 404 not found' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:not_found)
          end
        end

        context 'unauthorized publisher' do
          it 'returns 401 unauthorized and does not delete the envelope' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:unauthorized)
          end
        end

        context 'authorized publisher' do
          before do
            create(
              :organization_publisher,
              organization: organization,
              publisher: publisher
            )
          end

          it 'marks the envelope as deleted and purged' do
            expect { delete_envelope }.to change { envelope.reload.deleted_at }
              .from(nil).to(now)
              .and change { envelope.reload.purged_at }.from(nil).to(now)

            expect_status(:no_content)
          end
        end

        context 'super publisher' do
          let(:organization) {}
          let(:publisher) { create(:publisher, super_publisher: true) }

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and change { envelope.reload.purged_at }.from(nil).to(now)

            expect_status(:no_content)
          end
        end
      end
    end

    context 'explicit community' do
      let(:community) { navy }

      let(:delete_envelope) do
        travel_to now do
          delete "/navy/resources/documents/#{CGI.escape(ctid)}?purge=#{purge}",
                 nil,
                 'Authorization' => "Token #{auth_token}"
        end
      end

      context 'invalid token' do
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          delete_envelope
          expect_status(:unauthorized)
        end
      end

      context 'soft deletion' do
        let(:purge) { [nil, 0, 'no', false].sample }

        context 'nonexistent envelope' do
          let(:community) { ce_registry }

          it 'returns 404 not found' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }
            .and not_change { envelope_resource.reload.deleted_at }
            .and not_change { envelope.reload.purged_at }

            expect_status(:not_found)
          end
        end

        context 'unauthorized publisher' do
          it 'returns 401 unauthorized and does not delete the envelope' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:unauthorized)
          end
        end

        context 'authorized publisher' do
          before do
            create(
              :organization_publisher,
              organization: organization,
              publisher: publisher
            )
          end

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and not_change { envelope.reload.purged_at }

            expect_status(:no_content)
          end
        end

        context 'super publisher' do
          let(:organization) {}
          let(:publisher) { create(:publisher, super_publisher: true) }

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and not_change { envelope.reload.purged_at }

            expect_status(:no_content)
          end
        end
      end

      context 'physical deletion' do
        let(:purge) { [1, 'yes', true].sample }

        context 'nonexistent envelope' do
          let(:community) { ce_registry }

          it 'returns 404 not found' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:not_found)
          end
        end

        context 'unauthorized publisher' do
          it 'returns 401 unauthorized and does not delete the envelope' do
            expect { delete_envelope }.to not_change {
              envelope.reload.deleted_at
            }.and not_change { envelope.reload.purged_at }

            expect_status(:unauthorized)
          end
        end

        context 'authorized publisher' do
          before do
            create(
              :organization_publisher,
              organization: organization,
              publisher: publisher
            )
          end

          it 'marks the envelope as deleted and purged' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and change { envelope.reload.purged_at }.from(nil).to(now)

            expect_status(:no_content)
          end
        end

        context 'super publisher' do
          let(:organization) {}
          let(:publisher) { create(:publisher, super_publisher: true) }

          it 'deletes the envelope' do
            expect { delete_envelope }.to change {
              envelope.reload.deleted_at
            }.from(nil).to(now)
            .and change {
              envelope_resource.reload.deleted_at
            }.from(nil).to(now)
            .and change { envelope.reload.purged_at }.from(nil).to(now)

            expect_status(:no_content)
          end
        end
      end
    end
  end

  describe 'PATCH /resources/documents/:ctid/transfer' do
    let(:auth_token) { user.auth_token.value }
    let(:current_publisher) { create(:publisher, super_publisher: true) }
    let(:new_organization) { create(:organization) }
    let(:new_organization_id) { new_organization.id }
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
        travel_to now do
          patch "/resources/documents/#{CGI.escape(ctid)}/transfer?organization_id=#{new_organization_id}",
                nil,
                'Authorization' => "Token #{auth_token}"
        end

        envelope.reload
      end

      context 'invalid token' do
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          transfer_ownership
          expect_status(:unauthorized)
        end
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
            }.to not_change { envelope.envelope_ceterms_ctid }
            .and not_change { envelope.last_verified_on }
            .and not_change { envelope.organization }
            .and not_change { envelope.processed_resource }
            .and not_change { envelope.resource }
            .and not_change { envelope.resource_public_key }

            expect_status(:ok)
            expect_json(changed: false)
          end
        end

        context 'another organization' do
          it 'transfers ownership' do
            expect {
              transfer_ownership
            }.to change { envelope.last_verified_on }.to(now.to_date)
            .and change {
              envelope.organization
            }.from(organization).to(new_organization)
            .and(
              change { envelope.resource_public_key }
                .from(organization.key_pair.public_key)
                .to(new_organization.key_pair.public_key)
            )
            .and(not_change { envelope.envelope_ceterms_ctid })
            .and(not_change { envelope.processed_resource })

            expect_status(:ok)
            expect_json(changed: true)
            expect_json(last_verified_on: now.to_date.to_s)
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

        travel_to now do
          patch path, nil, 'Authorization' => "Token #{auth_token}"
        end

        envelope.reload
      end

      context 'invalid token' do
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          transfer_ownership
          expect_status(:unauthorized)
        end
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
              }.to not_change { envelope.envelope_ceterms_ctid }
              .and not_change { envelope.last_verified_on }
              .and not_change { envelope.organization }
              .and not_change { envelope.processed_resource }
              .and not_change { envelope.resource }
              .and not_change { envelope.resource_public_key }

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
              expect_json(last_verified_on: now.to_date.to_s)
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
              }.to change { envelope.last_verified_on }.to(now.to_date)
              .and change { envelope.publisher }.to(current_publisher)
              .and(not_change { envelope.envelope_ceterms_ctid })
              .and(not_change { envelope.organization })
              .and(not_change { envelope.processed_resource })
              .and(not_change { envelope.resource_public_key })

              expect_status(:ok)
              expect_json(changed: true)
              expect_json(last_verified_on: now.to_date.to_s)
            end
          end

          context 'another organization' do
            it 'transfers ownership' do
              expect {
                transfer_ownership
              }.to change { envelope.last_verified_on }.to(now.to_date)
              .and change {
                envelope.organization
              }.from(organization).to(new_organization)
              .and(
                change { envelope.resource_public_key }
                  .from(organization.key_pair.public_key)
                  .to(new_organization.key_pair.public_key)
              )
              .and(not_change { envelope.envelope_ceterms_ctid })
              .and(not_change { envelope.processed_resource })

              expect_status(:ok)
              expect_json(changed: true)
              expect_json(last_verified_on: now.to_date.to_s)
            end
          end
        end
      end
    end
  end
end
