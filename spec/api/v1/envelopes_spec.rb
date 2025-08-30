require_relative 'shared_examples/signed_endpoint'
require_relative '../../support/shared_contexts/envelopes_with_url'

RSpec.describe API::V1::Envelopes do
  let(:auth_token) { create(:user).auth_token.value }
  let!(:envelopes) { create_list(:envelope, 2) }
  let!(:envelope_community) { create(:envelope_community, name: 'ce_registry') }

  context 'GET /:community/community' do # rubocop:todo RSpec/ContextWording
    before { get '/learning-registry/community' }

    it { expect_status(:ok) }

    it 'retrieves the metadata community' do
      expect_json(name: 'learning_registry')
    end
  end

  context 'GET /:community/envelopes' do # rubocop:todo RSpec/ContextWording
    context 'public community' do # rubocop:todo RSpec/ContextWording
      let(:metadata_only) { false }

      before do
        get "/learning-registry/envelopes?metadata_only=#{metadata_only}"
      end

      it { expect_status(:ok) }

      it 'retrieves all the envelopes ordered by date' do
        expect_json_sizes(2)
        expect_json('0.envelope_id', envelopes.last.envelope_id)
        expect_json(
          '0.decoded_resource',
          **envelopes
            .last
            .processed_resource
            .symbolize_keys
            .slice(:name, :description, :url)
        )
      end

      it 'presents the JWT fields in decoded form' do
        expect_json('0.decoded_resource.name', 'The Constitution at Work')
      end

      # rubocop:todo RSpec/NestedGroups
      context 'providing a different metadata community' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'only retrieves envelopes from the provided community' do
          create(:envelope, :from_cer)

          get '/ce-registry/envelopes'

          expect_json_sizes(1)
          expect_json('0.envelope_community', 'ce_registry')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'metadata only' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:metadata_only) { true }

        it "returns only envelopes' metadata" do
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelopes.last.envelope_id)
          expect_json('0.resource', nil)
          expect_json('0.decoded_resource', nil)
        end
      end
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'secured community' do # rubocop:todo RSpec/ContextWording
      let(:api_key) { Faker::Lorem.characters }
      let(:cer) { EnvelopeCommunity.find_by(name: 'ce_registry') }
      let(:lr) { EnvelopeCommunity.find_by(name: 'learning_registry') }

      before do
        EnvelopeCommunity.update_all(secured: true)

        # rubocop:todo RSpec/MessageSpies
        expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          .with(api_key, lr)
          .at_least(:once)
          .and_return(api_key_validation_result)

        get '/learning-registry/envelopes',
            'Authorization' => "Token #{api_key}"
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key_validation_result) { true }

        it { expect_status(:ok) }

        it 'retrieves all the envelopes ordered by date' do
          expect_json_sizes(2)
          expect_json('0.envelope_id', envelopes.last.envelope_id)
        end

        it 'presents the JWT fields in decoded form' do
          expect_json('0.decoded_resource.name', 'The Constitution at Work')
        end

        # rubocop:todo RSpec/NestedGroups
        context 'providing a different metadata community' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            # rubocop:todo RSpec/MessageSpies
            expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
              # rubocop:enable RSpec/MessageSpies
              .with(api_key, cer)
              .at_least(:once)
              .and_return(api_key_validation_result)
          end

          it 'only retrieves envelopes from the provided community' do
            create(:envelope, :from_cer)

            get '/ce-registry/envelopes', 'Authorization' => "Token #{api_key}"

            expect_json_sizes(1)
            expect_json('0.envelope_community', 'ce_registry')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups

        let(:api_key_validation_result) { false }

        it { expect_status(:unauthorized) }
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'GET /:community/envelopes/downloads/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:finished_at) { nil }
    let(:internal_error_message) { nil }
    let(:started_at) { nil }

    let(:envelope_download) do
      create(
        :envelope_download,
        envelope_community:,
        finished_at:,
        internal_error_message:,
        started_at:
      )
    end

    let(:perform_request) do
      get "/envelopes/downloads/#{envelope_download.id}",
          'Authorization' => "Token #{auth_token}"
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'invalid token' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'all good' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      before do
        perform_request
        expect_status(:ok)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'in progress' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:started_at) { Time.current }

        it 'returns `in progress`' do
          expect_json('status', 'in progress')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'failed' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:finished_at) { Time.current }
        let(:internal_error_message) { Faker::Lorem.sentence }

        it 'returns `failed`' do
          expect_json('status', 'failed')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'finished' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:finished_at) { Time.current }

        it 'returns `finished` and URL' do
          expect_json('status', 'finished')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'pending' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns `pending`' do
          expect_json('status', 'pending')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'POST /:community/envelopes/downloads' do # rubocop:todo RSpec/ContextWording
    let(:perform_request) do
      post '/envelopes/downloads',
           nil,
           'Authorization' => "Token #{auth_token}"
    end

    context 'invalid token' do # rubocop:todo RSpec/ContextWording
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end

    context 'all good' do # rubocop:todo RSpec/ContextWording
      # rubocop:todo RSpec/MultipleExpectations
      it 'starts download' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          perform_request
        end.to change(EnvelopeDownload, :count).by(1)

        envelope_download = EnvelopeDownload.last
        expect(envelope_download.envelope_community.name).to eq('ce_registry')

        expect_status(:created)
        expect_json('id', envelope_download.id)

        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)

        enqueued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
        expect(enqueued_job[:args]).to eq([envelope_download.id])
        expect(enqueued_job[:job]).to eq(DownloadEnvelopesJob)
      end
    end
  end
end
