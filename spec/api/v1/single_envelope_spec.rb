require_relative 'shared_examples/missing_envelope'
require_relative 'shared_examples/signed_endpoint'

RSpec.describe API::V1::SingleEnvelope do
  context 'GET /:community/envelopes/:id' do # rubocop:todo RSpec/ContextWording
    let!(:envelopes) do
      create_list(:envelope, 2)
    end

    context 'by ID' do # rubocop:todo RSpec/ContextWording
      subject { envelopes.first }

      let(:id) { envelope.envelope_id }

      before do
        with_versioned_envelope(subject) do # rubocop:todo RSpec/NamedSubject
          # rubocop:todo RSpec/NamedSubject
          get "/learning-registry/envelopes/#{subject.envelope_id}"
          # rubocop:enable RSpec/NamedSubject
        end
      end

      it_behaves_like 'missing envelope', :get

      it { expect_status(:ok) }

      it 'retrieves the desired envelope' do
        # rubocop:todo RSpec/NamedSubject
        expect_json(envelope_community: subject.envelope_community.name)
        # rubocop:enable RSpec/NamedSubject
        expect_json(envelope_id: subject.envelope_id) # rubocop:todo RSpec/NamedSubject
        expect_json(resource_format: 'json')
        expect_json(resource_encoding: 'jwt')
      end

      it 'displays the appended node headers' do
        # rubocop:todo RSpec/NamedSubject
        base_url = "/learning-registry/envelopes/#{subject.envelope_id}"
        # rubocop:enable RSpec/NamedSubject

        expect_json_keys('node_headers', %i[resource_digest revision_history
                                            created_at updated_at deleted_at])
        expect_json('node_headers.revision_history.1', head: true)
        expect_json('node_headers.revision_history.1', url: base_url)
        expect_json('node_headers.revision_history.0', head: false)
        expect_json(
          'node_headers.revision_history.0',
          url: "#{base_url}/revisions/#{subject.versions.last.id}" # rubocop:todo RSpec/NamedSubject
        )
      end
    end

    context 'by CTID' do # rubocop:todo RSpec/ContextWording
      subject { envelopes.first }

      let(:ctid) { subject.envelope_ceterms_ctid.upcase }

      before do
        with_versioned_envelope(subject) do # rubocop:todo RSpec/NamedSubject
          get "/learning-registry/envelopes/#{ctid}"
        end
      end

      it_behaves_like 'missing envelope', :get

      it { expect_status(:ok) }

      it 'retrieves the desired envelope' do
        # rubocop:todo RSpec/NamedSubject
        expect_json(envelope_community: subject.envelope_community.name)
        # rubocop:enable RSpec/NamedSubject
        expect_json(envelope_id: subject.envelope_id) # rubocop:todo RSpec/NamedSubject
        expect_json(resource_format: 'json')
        expect_json(resource_encoding: 'jwt')
      end

      it 'displays the appended node headers' do
        # rubocop:todo RSpec/NamedSubject
        base_url = "/learning-registry/envelopes/#{subject.envelope_id}"
        # rubocop:enable RSpec/NamedSubject

        expect_json_keys('node_headers', %i[resource_digest revision_history
                                            created_at updated_at deleted_at])
        expect_json('node_headers.revision_history.1', head: true)
        expect_json('node_headers.revision_history.1', url: base_url)
        expect_json('node_headers.revision_history.0', head: false)
        expect_json(
          'node_headers.revision_history.0',
          url: "#{base_url}/revisions/#{subject.versions.last.id}" # rubocop:todo RSpec/NamedSubject
        )
      end
    end

    context 'by resource ID' do # rubocop:todo RSpec/ContextWording
      subject { envelopes.first }

      let(:resource_id) { resource.resource_id }

      before do
        with_versioned_envelope(subject) do # rubocop:todo RSpec/NamedSubject
          get "/learning-registry/envelopes/#{resource_id}"
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'bnode ID' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:resource) do
          create(
            :envelope_resource,
            envelope: subject,
            resource_id: "_:#{Faker::Internet.uuid}"
          )
        end

        it { expect_status(:not_found) }
      end

      # rubocop:todo RSpec/NestedGroups
      context 'full ID' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:resource) do
          create(
            :envelope_resource,
            envelope: subject,
            resource_id: Envelope.generate_ctid
          )
        end

        it_behaves_like 'missing envelope', :get

        it { expect_status(:ok) }

        it 'retrieves the desired envelope' do
          # rubocop:todo RSpec/NamedSubject
          expect_json(envelope_community: subject.envelope_community.name)
          # rubocop:enable RSpec/NamedSubject
          expect_json(envelope_id: subject.envelope_id) # rubocop:todo RSpec/NamedSubject
          expect_json(resource_format: 'json')
          expect_json(resource_encoding: 'jwt')
        end

        it 'displays the appended node headers' do
          # rubocop:todo RSpec/NamedSubject
          base_url = "/learning-registry/envelopes/#{subject.envelope_id}"
          # rubocop:enable RSpec/NamedSubject

          expect_json_keys('node_headers', %i[resource_digest revision_history
                                              created_at updated_at deleted_at])
          expect_json('node_headers.revision_history.1', head: true)
          expect_json('node_headers.revision_history.1', url: base_url)
          expect_json('node_headers.revision_history.0', head: false)
          expect_json(
            'node_headers.revision_history.0',
            # rubocop:todo RSpec/NamedSubject
            url: "#{base_url}/revisions/#{subject.versions.last.id}"
            # rubocop:enable RSpec/NamedSubject
          )
        end
      end
    end
  end

  context 'PATCH /:community/envelopes/:id/verify' do # rubocop:todo RSpec/ContextWording
    let(:envelope) { create(:envelope) }
    let(:last_verified_on) { Date.tomorrow }
    let(:params) { { last_verified_on: last_verified_on.to_s } }

    context 'without envelope' do
      it 'returns 404' do
        patch '/learning-registry/envelopes/nonexistent-id/verify', params

        expect_status(:not_found)
        expect_json_keys(:errors)
        expect_json('errors.0', 'Couldn\'t find Envelope')
      end
    end

    context 'with envelope' do
      it 'updates verification date' do
        expect do
          patch "/learning-registry/envelopes/#{envelope.envelope_id}/verify",
                params
        end.to change { envelope.reload.last_verified_on }.to(last_verified_on)

        expect_status(:ok)
        expect_json(changed: false)
        expect_json(last_verified_on: last_verified_on.to_date.to_s)
      end
    end
  end
end
