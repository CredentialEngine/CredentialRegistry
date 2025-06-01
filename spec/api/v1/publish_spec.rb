RSpec.describe API::V1::Publish do
  let(:ctid) { envelope.envelope_ceterms_ctid }
  let(:now) { Faker::Time.backward(days: 7).in_time_zone.change(usec: 0) }
  let(:organization) { create(:organization) }

  let!(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let!(:navy) { create(:envelope_community, name: 'navy') }

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  describe 'POST /resources/organizations/:organization_id/documents' do
    let(:publishing_organization) { create(:organization) }

    context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:user) { create(:user) }
      let(:user2) { create(:user) }

      let(:resource_json) do
        File.read(
          MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
        )
      end

      # rubocop:todo RSpec/NestedGroups
      context 'publish on behalf without token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          post "/resources/organizations/#{organization._ctid}/documents",
               resource_json
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      # rubocop:todo RSpec/ContextWording
      context 'publish on behalf with token, can publish on behalf of organization' do
        # rubocop:enable RSpec/ContextWording
        # rubocop:enable RSpec/NestedGroups
        let(:updated_resource_json) do
          resource = JSON(resource_json)
          resource['@graph'][0]['new_property'] = Faker::Lorem.sentence
          resource.to_json
        end

        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
        end

        # rubocop:todo RSpec/ExampleLength
        it 'returns the newly created envelope with a 201 Created HTTP status code' do
          # New envelope
          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                 resource_json, 'Authorization' => "Token #{user.auth_token.value}"
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
               resource_json, 'Authorization' => "Token #{user.auth_token.value}"

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
                 updated_resource_json, 'Authorization' => "Token #{user.auth_token.value}"
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
        # rubocop:enable RSpec/ExampleLength
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'publish on behalf with two tokens' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)

          travel_to now do
            post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                 resource_json,
                 'Authorization' => "Token #{user.auth_token.value}",
                 'Secondary-Token' => "Token #{user2.auth_token.value}"
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
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      # rubocop:todo RSpec/ContextWording
      context 'publish on behalf with token, can\'t publish on behalf of the organization' do
        # rubocop:enable RSpec/ContextWording
        # rubocop:enable RSpec/NestedGroups
        before do
          post "/resources/organizations/#{organization._ctid}/documents",
               resource_json, 'Authorization' => "Token #{user.auth_tokens.first.value}"
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'publish on behalf with token, super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'skip_validation' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          create(:organization_publisher, organization: organization, publisher: user.publisher)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'config enabled' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          # rubocop:todo RSpec/ExampleLength
          it 'skips resource validation when skip_validation=true is provided' do
            # ce/registry has skip_validation enabled
            bad_payload = attributes_for(:cer_org,
                                         resource: jwt_encode({ '@type' => 'ceterms:Badge' }))
            bad_payload.delete(:'ceterms:ctid')
            post "/resources/organizations/#{organization._ctid}/documents",
                 bad_payload.to_json,
                 'Authorization' => "Token #{user.auth_token.value}"
            expect_status(:unprocessable_entity)
            expect_json_keys(:errors)
            expect_json('errors.0', /ceterms:ctid : is required/)

            expect do
              travel_to now do
                # rubocop:todo Layout/LineLength
                post "/resources/organizations/#{organization._ctid}/documents?skip_validation=true",
                     # rubocop:enable Layout/LineLength
                     attributes_for(:cer_org,
                                    resource: jwt_encode({ '@type' => 'ceterms:Badge' })).to_json,
                     'Authorization' => "Token #{user.auth_token.value}"
              end
            end.to change(Envelope, :count).by(1)
            expect_status(:created)
            expect_json(changed: true)
            expect_json(last_verified_on: now.to_date.to_s)
          end
          # rubocop:enable RSpec/ExampleLength
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'republish under another organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      # rubocop:todo RSpec/ContextWording
      context 'publish on behalf with token, can access the publishing organization' do
        # rubocop:enable RSpec/ContextWording
        # rubocop:enable RSpec/NestedGroups
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
                 'Authorization' => "Token #{user.auth_token.value}"
          end
        end

        # rubocop:todo RSpec/ExampleLength
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
        # rubocop:enable RSpec/ExampleLength
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      # rubocop:todo RSpec/ContextWording
      context "publish on behalf with token, can't access the publishing organization" do
        # rubocop:enable RSpec/ContextWording
        # rubocop:enable RSpec/NestedGroups
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
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns a 401 unauthorized http status code' do
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end

  describe 'DELETE /resources/documents/:ctid' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:auth_token) { user.auth_token.value }
    let(:publisher) { create(:publisher) }
    let(:user) { create(:user, publisher: publisher) }

    let!(:envelope) do
      create(
        :envelope,
        :with_cer_credential,
        envelope_community: community,
        organization: organization
      )
    end

    let!(:envelope_resource) { envelope.envelope_resources.sole }

    let!(:indexed_envelope_resource) do
      create(:indexed_envelope_resource, envelope_resource:)
    end

    let!(:description_set) do
      create(:description_set, envelope_resource:)
    end

    before do
      community.update_column(:ocn_export_enabled, true)
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:community) { ce_registry }

      let(:delete_envelope) do
        delete "/resources/documents/#{CGI.escape(ctid)}",
               nil,
               'Authorization' => "Token #{auth_token}"
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:community) { navy }

        it 'returns 404 not found' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:not_found)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'unauthorized publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401 unauthorized and does not delete the envelope' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'authorized publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          create(
            :organization_publisher,
            organization: organization,
            publisher: publisher
          )
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'deletes the envelope' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            delete_envelope
          end.to change(Envelope, :count).by(-1)
                                         .and change(EnvelopeResource, :count).by(-1)
                                                                              .and change(
                                                                                # rubocop:todo Layout/LineLength
                                                                                IndexedEnvelopeResource, :count
                                                                                # rubocop:enable Layout/LineLength
                                                                              ).by(-1)
            .and change(
              DescriptionSet, :count
            ).by(-1)
            .and enqueue_job(DeleteFromOCNJob).with(
              envelope.envelope_ceterms_ctid, community.id
            )

          expect { envelope.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { indexed_envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { description_set.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect_status(:no_content)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:organization) {} # rubocop:todo Lint/EmptyBlock
        let(:publisher) { create(:publisher, super_publisher: true) }

        # rubocop:todo RSpec/MultipleExpectations
        it 'deletes the envelope' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            delete_envelope
          end.to change(Envelope, :count).by(-1)
                                         .and change(EnvelopeResource, :count).by(-1)
                                                                              .and change(
                                                                                # rubocop:todo Layout/LineLength
                                                                                IndexedEnvelopeResource, :count
                                                                                # rubocop:enable Layout/LineLength
                                                                              ).by(-1)
            .and change(
              DescriptionSet, :count
            ).by(-1)
            .and enqueue_job(DeleteFromOCNJob).with(
              envelope.envelope_ceterms_ctid, community.id
            )

          expect { envelope.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { indexed_envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { description_set.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect_status(:no_content)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'explicit community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:community) { navy }

      let(:delete_envelope) do
        delete "/navy/resources/documents/#{CGI.escape(ctid)}",
               nil,
               'Authorization' => "Token #{auth_token}"
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:community) { ce_registry }

        it 'returns 404 not found' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:not_found)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'unauthorized publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401 unauthorized and does not delete the envelope' do
          expect { delete_envelope }.not_to change(Envelope, :count)
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'authorized publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          create(
            :organization_publisher,
            organization: organization,
            publisher: publisher
          )
        end

        # rubocop:todo RSpec/MultipleExpectations
        it 'deletes the envelope' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            delete_envelope
          end.to change(Envelope, :count).by(-1)
                                         .and change(EnvelopeResource, :count).by(-1)
                                                                              .and change(
                                                                                # rubocop:todo Layout/LineLength
                                                                                IndexedEnvelopeResource, :count
                                                                                # rubocop:enable Layout/LineLength
                                                                              ).by(-1)
            .and change(
              DescriptionSet, :count
            ).by(-1)
            .and enqueue_job(DeleteFromOCNJob).with(
              envelope.envelope_ceterms_ctid, community.id
            )

          expect { envelope.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { indexed_envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { description_set.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect_status(:no_content)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:organization) {} # rubocop:todo Lint/EmptyBlock
        let(:publisher) { create(:publisher, super_publisher: true) }

        # rubocop:todo RSpec/MultipleExpectations
        it 'deletes the envelope' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          # rubocop:enable RSpec/MultipleExpectations
          expect do
            delete_envelope
          end.to change(Envelope, :count).by(-1)
                                         .and change(EnvelopeResource, :count).by(-1)
                                                                              .and change(
                                                                                # rubocop:todo Layout/LineLength
                                                                                IndexedEnvelopeResource, :count
                                                                                # rubocop:enable Layout/LineLength
                                                                              ).by(-1)
            .and change(
              DescriptionSet, :count
            ).by(-1)
            .and enqueue_job(DeleteFromOCNJob).with(
              envelope.envelope_ceterms_ctid, community.id
            )

          expect { envelope.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { indexed_envelope_resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { description_set.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect_status(:no_content)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  # rubocop:todo RSpec/MultipleMemoizedHelpers
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
        processed_resource: attributes_for(:cer_cred),
        publisher: original_publisher,
        resource: nil,
        resource_public_key: nil,
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

    context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:community) { ce_registry }

      let(:transfer_ownership) do
        travel_to now do
          # rubocop:todo Layout/LineLength
          patch "/resources/documents/#{CGI.escape(ctid)}/transfer?organization_id=#{new_organization_id}",
                # rubocop:enable Layout/LineLength
                nil,
                'Authorization' => "Token #{auth_token}"
        end

        envelope.reload
      end

      # rubocop:todo RSpec/NestedGroups
      context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          transfer_ownership
          expect_status(:unauthorized)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:community) { navy }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json('errors.0', 'Envelope not found')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

      # rubocop:todo RSpec/NestedGroups
      context 'user is not a super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

      # rubocop:todo RSpec/NestedGroups
      context 'user is a super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'same organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:new_organization) { organization }

          it 'changes nothing' do
            expect do
              transfer_ownership
            end.to not_change { envelope.envelope_ceterms_ctid }
              .and not_change { envelope.last_verified_on }
              .and not_change { envelope.organization }
              .and not_change { envelope.processed_resource }

            expect_status(:ok)
            expect_json(changed: false)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'another organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'transfers ownership' do # rubocop:todo RSpec/ExampleLength
            expect do
              transfer_ownership
            end.to change(envelope, :last_verified_on).to(now.to_date)
                                                      .and change(envelope,
                                                                  # rubocop:todo Layout/LineLength
                                                                  :organization).from(organization).to(new_organization)
                                                                                                   .and(not_change {
                                                                                                          envelope.envelope_ceterms_ctid
                                                                                                        })
                                                                                                   .and(not_change {
                                                                                                          envelope.processed_resource
                                                                                                        })

            expect_status(:ok)
            expect_json(changed: true)
            expect_json(last_verified_on: now.to_date.to_s)
          end
        end
      end
    end

    context 'explicit community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
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

      # rubocop:todo RSpec/NestedGroups
      context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { Faker::Lorem.characters }

        it 'returns a 401' do
          transfer_ownership
          expect_status(:unauthorized)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent envelope' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:community) { ce_registry }

        it 'returns 404' do
          transfer_ownership
          expect_status(:not_found)
          expect_json('errors.0', 'Envelope not found')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'nonexistent organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

      # rubocop:todo RSpec/NestedGroups
      context 'user is not a super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
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

      # rubocop:todo RSpec/NestedGroups
      context 'user is a super publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'same publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          # rubocop:todo RSpec/NestedGroups
          context 'same organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:new_organization) { organization }

            it 'changes nothing' do
              expect do
                transfer_ownership
              end.to not_change { envelope.envelope_ceterms_ctid }
                .and not_change { envelope.last_verified_on }
                .and not_change { envelope.organization }
                .and not_change { envelope.processed_resource }

              expect_status(:ok)
              expect_json(changed: false)
            end
          end

          # rubocop:todo RSpec/NestedGroups
          context 'another organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            it 'transfers ownership' do # rubocop:todo RSpec/ExampleLength
              expect do
                transfer_ownership
              end.to change {
                envelope.reload.organization
              }.from(organization).to(new_organization)
                                  .and(not_change { envelope.reload.envelope_ceterms_ctid })
                                  .and(not_change { envelope.reload.processed_resource })
                                  .and(not_change { envelope.reload.publisher })

              expect_status(:ok)
              expect_json(changed: true)
              expect_json(last_verified_on: now.to_date.to_s)
            end
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'another publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:original_publisher) { create(:publisher) }

          # rubocop:todo RSpec/NestedGroups
          context 'same organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:new_organization) { organization }

            it 'changes publisher only' do # rubocop:todo RSpec/ExampleLength
              expect do
                transfer_ownership
              end.to change(envelope, :last_verified_on).to(now.to_date)
                                                        .and change(envelope,
                                                                    :publisher).to(current_publisher)
                                                                               # rubocop:enable Layout/LineLength
                                                                               .and(not_change {
                                                                                      # rubocop:todo Layout/LineLength
                                                                                      envelope.envelope_ceterms_ctid
                                                                                      # rubocop:enable Layout/LineLength
                                                                                    })
                                                                               .and(not_change {
                                                                                      # rubocop:todo Layout/LineLength
                                                                                      envelope.organization
                                                                                      # rubocop:enable Layout/LineLength
                                                                                    })
                                                                               .and(not_change {
                                                                                      # rubocop:todo Layout/LineLength
                                                                                      envelope.processed_resource
                                                                                      # rubocop:enable Layout/LineLength
                                                                                    })

              expect_status(:ok)
              expect_json(changed: true)
              expect_json(last_verified_on: now.to_date.to_s)
            end
          end

          # rubocop:todo RSpec/NestedGroups
          context 'another organization' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            it 'transfers ownership' do # rubocop:todo RSpec/ExampleLength
              expect do
                transfer_ownership
              end.to change(envelope, :last_verified_on).to(now.to_date)
                                                        .and change(envelope,
                                                                    # rubocop:todo Lint/MissingCopEnableDirective
                                                                    # rubocop:todo Layout/LineLength
                                                                    # rubocop:enable Lint/MissingCopEnableDirective
                                                                    :organization).from(organization).to(new_organization)
                                                                                                     .and(not_change {
                                                                                                            envelope.envelope_ceterms_ctid
                                                                                                          })
                                                                                                     .and(not_change {
                                                                                                            envelope.processed_resource
                                                                                                          })

              expect_status(:ok)
              expect_json(changed: true)
              expect_json(last_verified_on: now.to_date.to_s)
            end
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
