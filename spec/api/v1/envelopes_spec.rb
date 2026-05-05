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
  context 'GET /:community/envelopes/download' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:finished_at) { nil }
    let(:internal_error_message) { nil }
    let(:started_at) { nil }
    let(:url) { nil }

    let(:perform_request) do
      get '/envelopes/download', 'Authorization' => "Token #{auth_token}"
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'with invalid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'with valid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'without envelope download' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'creates new pending download' do
          expect { perform_request }.to change(EnvelopeDownload, :count).by(1)
          expect_status(:ok)

          envelope_download = EnvelopeDownload.last
          expect(envelope_download.envelope_community).to eq(envelope_community)
          expect(envelope_download.status).to eq('pending')

          expect_json_sizes(3)
          expect_json('last_published_at', nil)
          expect_json('enqueued_at', nil)
          expect_json('status', 'pending')
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with envelope download' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let!(:envelope_download) do
          create(
            :envelope_download,
            envelope_community:,
            finished_at:,
            internal_error_message:,
            started_at:,
            status:,
            zip_files:,
            url:
          )
        end

        let(:zip_files) { [] }

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'in progress' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:status) { :in_progress }

          it 'returns `in progress`' do
            expect { perform_request }.not_to change(EnvelopeDownload, :count)
            expect_status(:ok)
            expect_json_sizes(3)
            expect_json('last_published_at', nil)
            expect_json('started_at', envelope_download.started_at.as_json)
            expect_json('status', 'in_progress')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'failed' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:internal_error_message) { Faker::Lorem.sentence }
          let(:status) { :finished }
          let(:url) { Faker::Internet.url }
          let(:zip_files) { [url] }

          it 'returns `failed`' do
            expect { perform_request }.not_to change(EnvelopeDownload, :count)
            expect_status(:ok)
            expect_json_sizes(5)
            expect_json('last_published_at', nil)
            expect_json('finished_at', envelope_download.finished_at.as_json)
            expect_json('status', 'failed')
            expect_json('url', url)
            expect_json('zip_files', zip_files)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'finished' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:finished_at) { Time.current }
          let(:status) { :finished }
          let(:url) { Faker::Internet.url }
          let(:zip_files) { [url, "#{url}/second.zip"] }

          it 'returns `finished` and URL' do
            expect { perform_request }.not_to change(EnvelopeDownload, :count)
            expect_status(:ok)
            expect_json_sizes(5)
            expect_json('last_published_at', nil)
            expect_json('finished_at', envelope_download.finished_at.as_json)
            expect_json('status', 'finished')
            expect_json('url', url)
            expect_json('zip_files', zip_files)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'pending' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          let(:status) { :pending }

          # rubocop:enable RSpec/NestedGroups
          it 'returns `pending`' do
            expect { perform_request }.not_to change(EnvelopeDownload, :count)
            expect_status(:ok)
            expect_json('status', 'pending')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'POST /:community/envelopes/download' do # rubocop:todo RSpec/ContextWording
    let(:perform_request) do
      post '/envelopes/download', nil, 'Authorization' => "Token #{auth_token}"
    end

    before do
      PaperTrail.enabled = true
    end

    after do
      PaperTrail.enabled = false
    end

    context 'with invalid token' do
      let(:auth_token) { 'invalid token' }

      before do
        perform_request
      end

      it 'returns 401' do
        expect_status(:unauthorized)
      end
    end

    context 'with valid token' do
      let(:now) { Time.current.change(usec: 0) }

      context 'without envelope download' do # rubocop:todo RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleExpectations
        it 'creates new pending download and enqueues job' do # rubocop:todo RSpec/ExampleLength
          # rubocop:enable RSpec/MultipleExpectations
          published_at = now - 5.minutes

          travel_to published_at do
            create(:envelope, :from_cer, envelope_community:)
          end

          travel_to now do
            expect { perform_request }.to change(EnvelopeDownload, :count).by(1)
          end

          expect_status(:created)

          envelope_download = EnvelopeDownload.last
          expect(envelope_download.envelope_community).to eq(envelope_community)
          expect(envelope_download.last_published_at).to eq(published_at)
          expect(envelope_download.status).to eq('pending')

          expect_json_sizes(3)
          expect_json('last_published_at', published_at.as_json)
          expect_json('enqueued_at', now.as_json)
          expect_json('status', 'pending')

          jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          matching_jobs = jobs.select { |job| job.fetch('job_class') == 'DownloadEnvelopesJob' }
          expect(matching_jobs.size).to eq(1)

          job = matching_jobs.first
          expect(job.fetch('arguments')).to eq([envelope_download.id])
          expect(job.fetch('job_class')).to eq('DownloadEnvelopesJob')
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'with envelope download' do # rubocop:todo RSpec/NestedGroups
        let!(:envelope_download) do
          create(:envelope_download, :finished, envelope_community:)
        end
        let(:published_at) { now - 10.minutes }

        before do
          travel_to published_at do
            create(:envelope, :from_cer, envelope_community:)
          end
        end

        it 'returns the existing download when no newer publish event exists' do
          envelope_download.update!(last_published_at: published_at)

          expect { perform_request }.to not_enqueue_job(DownloadEnvelopesJob)

          expect_status(:ok)
          expect(envelope_download.reload.status).to eq('finished')
          expect(envelope_download.last_published_at).to eq(published_at)

          expect_json('finished_at', envelope_download.finished_at.as_json)
          expect_json('status', 'finished')
        end

        it 'enqueues job for existing download when there is a newer publish event' do
          previous_publish_time = published_at - 5.minutes
          envelope_download.update!(last_published_at: previous_publish_time)

          travel_to now do
            expect { perform_request }.to not_change(EnvelopeDownload, :count)
              .and enqueue_job(DownloadEnvelopesJob).with(envelope_download.id)
          end

          expect_status(:created)
          expect(envelope_download.reload.status).to eq('pending')
          expect(envelope_download.last_published_at).to eq(published_at)

          expect_json_sizes(3)
          expect_json('last_published_at', published_at.as_json)
          expect_json('enqueued_at', now.as_json)
          expect_json('status', 'pending')
        end

        it 'clears previous failure fields when retrying a failed download' do
          envelope_download.update!(
            argo_workflow_name: 'old-workflow',
            argo_workflow_namespace: 'credreg-staging',
            finished_at: 5.minutes.ago.change(usec: 0),
            internal_error_backtrace: ['boom'],
            internal_error_message: 'zip task failed',
            url: 'https://downloads.example/old.zip',
            zip_files: ['old.zip']
          )
          envelope_download.update!(last_published_at: published_at - 5.minutes)

          travel_to now do
            expect { perform_request }.to enqueue_job(DownloadEnvelopesJob).with(envelope_download.id)
          end

          expect_status(:created)

          envelope_download.reload
          expect(envelope_download.status).to eq('pending')
          expect(envelope_download.enqueued_at).to eq(now)
          expect(envelope_download.finished_at).to be_nil
          expect(envelope_download.internal_error_message).to be_nil
          expect(envelope_download.internal_error_backtrace).to eq([])
          expect(envelope_download.last_published_at).to eq(published_at)
          expect(envelope_download.url).to be_nil
          expect(envelope_download.zip_files).to eq([])
          expect(envelope_download.argo_workflow_name).to be_nil
          expect(envelope_download.argo_workflow_namespace).to be_nil

          expect_json_sizes(3)
          expect_json('last_published_at', published_at.as_json)
          expect_json('enqueued_at', now.as_json)
          expect_json('status', 'pending')
        end

        it 'does not enqueue a duplicate job when the download is already pending' do
          envelope_download.update!(
            enqueued_at: now,
            last_published_at: published_at - 5.minutes,
            status: :pending
          )

          expect { perform_request }.to not_enqueue_job(DownloadEnvelopesJob)

          expect_status(:ok)
          expect(envelope_download.reload.status).to eq('pending')
          expect_json_sizes(3)
          expect_json('last_published_at', envelope_download.last_published_at.as_json)
          expect_json('enqueued_at', now.as_json)
          expect_json('status', 'pending')
        end

        it 'does not enqueue a duplicate job when the download is already in progress' do
          envelope_download.update!(
            last_published_at: published_at - 5.minutes,
            started_at: now,
            status: :in_progress
          )

          expect { perform_request }.to not_enqueue_job(DownloadEnvelopesJob)

          expect_status(:ok)
          expect(envelope_download.reload.status).to eq('in_progress')
          expect_json_sizes(3)
          expect_json('last_published_at', envelope_download.last_published_at.as_json)
          expect_json('started_at', now.as_json)
          expect_json('status', 'in_progress')
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end
end
