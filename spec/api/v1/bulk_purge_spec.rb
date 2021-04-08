RSpec.describe API::V1::BulkPurge do
  context 'DELETE /:community/envelopes' do
    let(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
    let(:navy) { create(:envelope_community, name: 'navy') }
    let(:publisher) { create(:organization) }
    let(:user) { create(:user) }

    let!(:envelope1) do
      create(
        :envelope,
        created_at: Date.new(2020, 2, 29),
        envelope_community: ce_registry,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_org))
      )
    end

    let!(:envelope2) do
      create(
        :envelope,
        created_at: Date.new(2020, 3, 13),
        envelope_community: ce_registry,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    let!(:envelope3) do
      create(
        :envelope,
        created_at: Date.new(2020, 4, 1),
        envelope_community: navy,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    let!(:envelope4) do
      create(
        :envelope,
        created_at: Date.new(2020, 9, 12),
        envelope_community: navy,
        publishing_organization: publisher,
        resource: jwt_encode(attributes_for(:cer_cred))
      )
    end

    let!(:envelope5) do
      create(
        :envelope,
        :with_cer_credential,
        created_at: Date.new(2020, 4, 1),
        envelope_community: ce_registry
      )
    end

    context 'authentication' do
      before do
        delete "/envelopes?published_by=#{publisher._ctid}",
               'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end

    context 'default community' do
      context 'without optional' do
        it 'purges envelopes' do
          expect {
            delete "/envelopes?published_by=#{publisher._ctid}",
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-2)
          .and change { Envelope.exists?(id: envelope1.id) }.to(false)
          .and change { Envelope.exists?(id: envelope2.id) }.to(false)

          expect_json(purged: 2)
        end
      end

      context 'with resource_type' do
        it 'purges envelopes' do
          expect {
            delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&resource_type=organization',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-1)
          .and change { Envelope.exists?(id: envelope1.id) }.to(false)

          expect_json(purged: 1)
        end
      end

      context 'with from' do
        it 'purges envelopes' do
          expect {
            delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&from=2020-03-08T00:00:00',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-1)
          .and change { Envelope.exists?(id: envelope2.id) }.to(false)

          expect_json(purged: 1)
        end
      end

      context 'with until' do
        it 'purges envelopes' do
          expect {
            delete "/envelopes?published_by=#{publisher._ctid}" \
                     '&until=2020-04-01T00:00:00',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-2)
          .and change { Envelope.exists?(id: envelope1.id) }.to(false)
          .and change { Envelope.exists?(id: envelope2.id) }.to(false)

          expect_json(purged: 2)
        end
      end
    end

    context 'explicit community' do
      context 'without optional' do
        it 'purges envelopes' do
          expect {
            delete "/navy/envelopes?published_by=#{publisher._ctid}",
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-2)
          .and change { Envelope.exists?(id: envelope3.id) }.to(false)
          .and change { Envelope.exists?(id: envelope4.id) }.to(false)

          expect_json(purged: 2)
        end
      end

      context 'with resource_type' do
        it 'purges envelopes' do
          expect {
            delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&resource_type=credential',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-2)
          .and change { Envelope.exists?(id: envelope3.id) }.to(false)
          .and change { Envelope.exists?(id: envelope4.id) }.to(false)

          expect_json(purged: 2)
        end
      end

      context 'with from' do
        it 'purges envelopes' do
          expect {
            delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&from=2020-04-02T00:00:00',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-1)
          .and change { Envelope.exists?(id: envelope4.id) }.to(false)

          expect_json(purged: 1)
        end
      end

      context 'with until' do
        it 'purges envelopes' do
          expect {
            delete "/navy/envelopes?published_by=#{publisher._ctid}" \
                     '&until=2020-09-11T00:00:00',
                   nil,
                   'Authorization' => "Token #{user.auth_token.value}"
          }.to change { Envelope.count }.by(-1)
          .and change { Envelope.exists?(id: envelope3.id) }.to(false)

          expect_json(purged: 1)
        end
      end
    end
  end
end
