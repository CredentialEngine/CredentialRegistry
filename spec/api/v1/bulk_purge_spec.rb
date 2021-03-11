RSpec.describe API::V1::BulkPurge do
  context 'DELETE /:community/envelopes' do
    let(:publisher) { create(:organization) }
    let(:user) { create(:user) }

    let!(:envelope1) do
      create(
        :envelope,
        created_at: Date.new(2020, 2, 29),
        publishing_organization: publisher,
        resource_type: 'assessment'
      )
    end

    let!(:envelope2) do
      create(
        :envelope,
        created_at: Date.new(2020, 3, 13),
        publishing_organization: publisher,
        resource_type: 'competency'
      )
    end

    let!(:envelope3) do
      create(
        :envelope,
        created_at: Date.new(2020, 4, 1),
        publishing_organization: publisher,
        resource_type: 'credential'
      )
    end

    let!(:envelope4) do
      create(
        :envelope,
        created_at: Date.new(2020, 9, 12),
        publishing_organization: publisher,
        resource_type: 'competency'
      )
    end

    let!(:envelope5) do
      create(
        :envelope,
        created_at: Date.new(2020, 4, 1),
        resource_type: 'competency'
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

    context 'without optional' do
      it 'purges envelopes' do
        expect {
          delete "/envelopes?published_by=#{publisher._ctid}",
                 nil,
                 'Authorization' => "Token #{user.auth_token.value}"
        }.to change { Envelope.count }.by(-4)

        expect { envelope1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope3.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope4.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect_json(purged: 4)
      end
    end

    context 'with resource_type' do
      it 'purges envelopes' do
        expect {
          delete "/envelopes?published_by=#{publisher._ctid}" \
                   '&resource_type=competency',
                 nil,
                 'Authorization' => "Token #{user.auth_token.value}"
        }.to change { Envelope.count }.by(-2)

        expect { envelope2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope4.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect_json(purged: 2)
      end
    end

    context 'with from' do
      it 'purges envelopes' do
        expect {
          delete "/envelopes?published_by=#{publisher._ctid}" \
                   '&from=2020-04-01T00:00:00',
                 nil,
                 'Authorization' => "Token #{user.auth_token.value}"
        }.to change { Envelope.count }.by(-2)

        expect { envelope3.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope4.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect_json(purged: 2)
      end
    end

    context 'with until' do
      it 'purges envelopes' do
        expect {
          delete "/envelopes?published_by=#{publisher._ctid}" \
                   '&until=2020-04-01T00:00:00',
                 nil,
                 'Authorization' => "Token #{user.auth_token.value}"
        }.to change { Envelope.count }.by(-3)

        expect { envelope1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { envelope3.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect_json(purged: 3)
      end
    end
  end
end
