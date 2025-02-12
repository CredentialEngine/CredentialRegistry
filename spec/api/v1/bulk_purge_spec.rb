RSpec.describe API::V1::BulkPurge do
  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'DELETE /:community/envelopes' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
    let(:navy) { create(:envelope_community, name: 'navy') }
    let(:owner) { create(:organization) }
    let(:publisher) { create(:organization) }
    let(:user) { create(:user) }

    let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
      create(
        :envelope,
        created_at: Date.new(2020, 2, 29),
        envelope_community: ce_registry,
        organization: owner,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_org))
      )
    end

    let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
      create(
        :envelope,
        created_at: Date.new(2020, 3, 13),
        envelope_community: ce_registry,
        organization: owner,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
      create(
        :envelope,
        created_at: Date.new(2020, 4, 1),
        envelope_community: navy,
        organization: owner,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    let!(:envelope4) do # rubocop:todo RSpec/IndexedLet
      create(
        :envelope,
        created_at: Date.new(2020, 9, 12),
        envelope_community: navy,
        organization: owner,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    # rubocop:todo RSpec/LetSetup
    let!(:envelope5) do # rubocop:todo RSpec/IndexedLet, RSpec/LetSetup
      # rubocop:enable RSpec/LetSetup
      create(
        :envelope,
        :with_cer_credential,
        created_at: Date.new(2020, 4, 1),
        envelope_community: ce_registry
      )
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'authentication' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        delete '/envelopes', 'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'by owner' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'without optional' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/envelopes?owned_by=#{owner._ctid}",
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope2.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with resource_type' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/envelopes?owned_by=#{owner._ctid}" \
                     '&resource_type=organization',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with from' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/envelopes?owned_by=#{owner._ctid}" \
                     '&from=2020-03-08T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope2.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with until' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/envelopes?owned_by=#{owner._ctid}" \
                     '&until=2020-04-01T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope2.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'explicit community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'without optional' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/navy/envelopes?owned_by=#{owner._ctid}",
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope4.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with resource_type' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/navy/envelopes?owned_by=#{owner._ctid}" \
                     '&resource_type=credential',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope4.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with from' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/navy/envelopes?owned_by=#{owner._ctid}" \
                     '&from=2020-04-02T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope4.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with until' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/navy/envelopes?owned_by=#{owner._ctid}" \
                     '&until=2020-09-11T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'by publisher' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'without optional' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/envelopes?published_by=#{publisher._ctid}",
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope2.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with resource_type' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&resource_type=organization',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with from' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&from=2020-03-08T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope2.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with until' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&until=2020-04-01T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope1.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope2.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'explicit community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'without optional' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/navy/envelopes?published_by=#{publisher._ctid}",
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope4.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with resource_type' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do # rubocop:todo RSpec/ExampleLength
            expect do
              delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&resource_type=credential',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-2)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)
                                                 .and change {
                                                        Envelope.exists?(id: envelope4.id)
                                                      }.to(false)

            expect_json(purged: 2)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with from' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&from=2020-04-02T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope4.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with until' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'purges envelopes' do
            expect do
              delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&until=2020-09-11T00:00:00',
                     nil,
                     'Authorization' => "Token #{user.auth_token.value}"
            end.to change(Envelope, :count).by(-1)
                                           .and change {
                                                  Envelope.exists?(id: envelope3.id)
                                                }.to(false)

            expect_json(purged: 1)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
