RSpec.describe API::V1::Graph do
  let(:auth_token) { create(:user).auth_token.value }

  # rubocop:todo RSpec/MultipleMemoizedHelpers
  context 'default community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
    let(:envelope_community) { ec }

    let!(:ec)       { create(:envelope_community, name: 'ce_registry') }
    let!(:envelope) { create(:envelope, :from_cer, :with_cer_credential) }
    let(:resource) { envelope.processed_resource }
    let(:full_id)  { resource['@id'] }
    let(:id)       { full_id.split('/').last }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:resource_json) do
      content = File.read MR.root_path.join('db', 'seeds', 'ce_registry', 'credential.json')
      JSON.parse(content).first.to_json
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /graph/:id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctid) { Faker::Lorem.characters(number: 10) }
      let(:full_id) do
        "http://credentialengineregistry.org/resources/#{ctid}"
      end
      let(:id_field) { nil }
      let(:resource_with_ids) do
        resource.merge('@id' => full_id, 'ceterms:ctid' => ctid)
      end

      before do
        allow_any_instance_of(EnvelopeCommunity) # rubocop:todo RSpec/AnyInstance
          .to receive(:id_field).and_return(id_field)

        create(
          :envelope,
          :from_cer,
          :with_cer_credential,
          envelope_community: ec,
          processed_resource: resource_with_ids
        )

        get "/graph/#{CGI.escape(id).upcase}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without `id_field`' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by short ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource by looking at the prefix' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with `id_field`' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id_field) { 'ceterms:ctid' }

        # rubocop:todo RSpec/RepeatedExampleGroupBody
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/RepeatedExampleGroupBody

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID, downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid.downcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by custom ID, upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid.upcase }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/RepeatedExampleGroupBody
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by short ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/RepeatedExampleGroupBody
          # rubocop:enable RSpec/NestedGroups
          let(:id) { ctid }

          it 'retrieves the desired resource' do
            expect_status(:ok)
            expect_json('@id': full_id)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/RepeatedExampleGroupBody
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with graph resources' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:id_field) { 'ceterms:ctid' }
        let(:resource_with_ids) do
          attributes_for(:cer_graph_competency_framework, ctid: ctid)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by ID internal to the graph' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:competency_id) do
            resource_with_ids[:@graph]
              .find { |obj| obj[:@type] == 'ceasn:Competency' }[:'ceterms:ctid']
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { competency_id.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
              expect(json_body[:@graph].map do |o|
                o[:'ceterms:ctid']
              end).to include(competency_id)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { competency_id.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
              expect(json_body[:@graph].map do |o|
                o[:'ceterms:ctid']
              end).to include(competency_id)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by primary ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'upcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { ctid.upcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'downcase' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:id) { ctid.downcase }

            it 'retrieves the desired resource' do
              expect_status(:ok)
              expect_json('@id': full_id)
              expect(json_body).to have_key(:@graph)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'by bnode ID' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:id) do
            resource_with_ids[:@graph]
              .find { |obj| obj[:@id].start_with?('_') }[:'ceterms:ctid']
          end

          it 'cannot retrieve the desired resource' do
            expect_status(:not_found)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'POST /graph/search' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential)
      end

      before do
        post '/graph/search',
             {
               ctids: [
                 envelope1.envelope_ceterms_ctid.upcase,
                 envelope2.envelope_ceterms_ctid.upcase,
                 envelope3.envelope_ceterms_ctid.upcase
               ]
             }
      end

      it 'fetches graphs with the given CTIDs' do
        expect_status(:ok)
        expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                       envelope2.processed_resource)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'GET /:community/graph/download' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:finished_at) { nil }
      let(:internal_error_message) { nil }
      let(:started_at) { nil }
      let(:url) { nil }

      let(:perform_request) do
        get '/graph/download', 'Authorization' => "Token #{auth_token}"
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'with invalid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { 'invalid token' }

        before do
          perform_request
        end

        it 'returns 401' do
          expect_status(:unauthorized)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/NestedGroups
      context 'with valid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'without envelope download' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          it 'creates new pending download' do
            expect { perform_request }.to change(EnvelopeDownload, :count).by(1)
            expect_status(:ok)

            envelope_download = EnvelopeDownload.last
            expect(envelope_download.envelope_community).to eq(envelope_community)
            expect(envelope_download.status).to eq('pending')

            expect_json_sizes(2)
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
              type: :graph,
              url:
            )
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'in progress' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:status) { :in_progress }

            it 'returns `in progress`' do
              expect { perform_request }.not_to change(EnvelopeDownload, :count)
              expect_status(:ok)
              expect_json_sizes(2)
              expect_json('started_at', envelope_download.started_at.as_json)
              expect_json('status', 'in_progress')
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'failed' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:finished_at) { Time.current }
            let(:status) { :failed }
            let(:url) { Faker::Internet.url }

            it 'returns `failed`' do
              expect { perform_request }.not_to change(EnvelopeDownload, :count)
              expect_status(:ok)
              expect_json_sizes(3)
              expect_json('finished_at', envelope_download.finished_at.as_json)
              expect_json('status', 'failed')
              expect_json('url', url)
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

            it 'returns `finished` and URL' do
              expect { perform_request }.not_to change(EnvelopeDownload, :count)
              expect_status(:ok)
              expect_json_sizes(3)
              expect_json('finished_at', envelope_download.finished_at.as_json)
              expect_json('status', 'finished')
              expect_json('url', url)
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

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'POST /:community/graph/download' do # rubocop:todo RSpec/ContextWording
      let(:perform_request) do
        post '/graph/download', nil, 'Authorization' => "Token #{auth_token}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with invalid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:auth_token) { 'invalid token' }

        before do
          perform_request
        end

        it 'returns 401' do
          expect_status(:unauthorized)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with valid token' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:now) { Time.current.change(usec: 0) }

        context 'without envelope download' do # rubocop:todo RSpec/NestedGroups
          # rubocop:todo RSpec/MultipleExpectations
          it 'creates new pending download and enqueues job' do # rubocop:todo RSpec/ExampleLength
            # rubocop:enable RSpec/MultipleExpectations
            travel_to now do
              expect { perform_request }.to change(EnvelopeDownload, :count).by(1)
            end

            expect_status(:created)

            envelope_download = EnvelopeDownload.last
            expect(envelope_download.envelope_community).to eq(envelope_community)
            expect(envelope_download.status).to eq('pending')

            expect_json_sizes(2)
            expect_json('enqueued_at', now.as_json)
            expect_json('status', 'pending')

            expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)

            job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
            expect(job.fetch('arguments')).to eq([envelope_download.id])
            expect(job.fetch('job_class')).to eq('DownloadEnvelopesJob')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        context 'with envelope download' do # rubocop:todo RSpec/NestedGroups
          let!(:envelope_download) do
            create(:envelope_download, :finished, envelope_community:, type: :graph)
          end

          it 'enqueues job for existing download' do
            travel_to now do
              expect { perform_request }.to not_change(EnvelopeDownload, :count)
                .and enqueue_job(DownloadEnvelopesJob).with(envelope_download.id)
            end

            expect_status(:created)
            expect(envelope_download.reload.status).to eq('pending')

            expect_json_sizes(2)
            expect_json('enqueued_at', now.as_json)
            expect_json('status', 'pending')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
    end
  end

  context 'with community' do
    let!(:name) { ec.name }

    let(:ec) do
      create(
        :envelope_community,
        default: true,
        name: 'ce_registry',
        secured: secured
      )
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'GET /:community_name/graph/:id' do # rubocop:todo RSpec/ContextWording
      let!(:id) { '123-123-123' }
      let!(:processed_resource) { attributes_for(:cer_org).merge('@id': id) }
      let!(:envelope) do # rubocop:todo RSpec/LetSetup
        create(:envelope, :from_cer, :with_cer_credential,
               processed_resource:, envelope_community: ec)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'public community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:secured) { false }

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).not_to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
        end

        # rubocop:todo RSpec/NestedGroups
        describe 'retrieves the desired resource' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/graph/#{id}"
          end

          it { expect_status(:ok) }
          it { expect_json('@id': id) }
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'wrong community_name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/learning_registry/graph/#{id}"
          end

          it { expect_status(:not_found) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          before do
            get "/#{name}/graph/'9999INVALID'"
          end

          it { expect_status(:not_found) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'secured community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
            # rubocop:enable RSpec/MessageSpies
            # rubocop:enable RSpec/StubbedMock
            .with(api_key, ec)
            .and_return(api_key_validation_result)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { true }

          # rubocop:todo RSpec/NestedGroups
          describe 'retrieves the desired resource' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            before do
              get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:ok) }
            it { expect_json('@id': id) }
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'invalid id' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            before do
              get "/#{name}/graph/'9999INVALID'",
                  'Authorization' => "Token #{api_key}"
            end

            it { expect_status(:not_found) }
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { false }

          before do
            get "/#{name}/graph/#{id}", 'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'POST /:community_name/graph/search' do # rubocop:todo RSpec/ContextWording
      let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential, envelope_community: ec)
      end

      let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
        create(:envelope, :with_cer_credential)
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'public community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:secured) { false }

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).not_to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies

          post '/ce_registry/graph/search',
               {
                 ctids: [
                   envelope1.envelope_ceterms_ctid,
                   envelope2.envelope_ceterms_ctid,
                   envelope3.envelope_ceterms_ctid
                 ]
               }
        end

        it 'fetches graphs with the given CTIDs' do
          expect_status(:ok)
          expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                         envelope2.processed_resource)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'secured community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:api_key) { Faker::Lorem.characters }
        let(:secured) { true }

        before do
          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(ValidateApiKey).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
            # rubocop:enable RSpec/MessageSpies
            # rubocop:enable RSpec/StubbedMock
            .with(api_key, ec)
            .and_return(api_key_validation_result)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'authenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { true }

          before do
            post '/ce_registry/graph/search',
                 {
                   ctids: [
                     envelope1.envelope_ceterms_ctid,
                     envelope2.envelope_ceterms_ctid,
                     envelope3.envelope_ceterms_ctid
                   ]
                 },
                 'Authorization' => "Token #{api_key}"
          end

          it 'fetches graphs with the given CTIDs' do
            expect_status(:ok)
            expect(JSON(response.body)).to contain_exactly(envelope1.processed_resource,
                                                           envelope2.processed_resource)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'unauthenticated' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:api_key_validation_result) { false }

          before do
            post '/ce_registry/graph/search',
                 {
                   ctids: [
                     envelope1.envelope_ceterms_ctid,
                     envelope2.envelope_ceterms_ctid,
                     envelope3.envelope_ceterms_ctid
                   ]
                 },
                 'Authorization' => "Token #{api_key}"
          end

          it { expect_status(:unauthorized) }
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
