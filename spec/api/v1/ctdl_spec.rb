require 'spec_helper'

RSpec.describe API::V1::Ctdl do
  context 'POST /ctdl' do # rubocop:todo RSpec/ContextWording
    let(:auth_token) { create(:auth_token).value }

    let(:query) do
      {
        '@type' => 'ceterms:Certificate',
        'search:termGroup' => [
          {
            'ceterms:name' => 'accounting',
            'ceterms:description' => 'accounting'
          },
          {
            'ceterms:keyword' => 'finance'
          }
        ]
      }
    end

    let!(:cer) { create(:envelope_community, name: 'ce_registry') }
    let!(:navy) { create(:envelope_community, name: 'navy') }

    context 'invalid token' do # rubocop:todo RSpec/ContextWording
      let(:auth_token) { Faker::Lorem.characters }

      it 'returns a 401' do
        post '/ctdl',
             query.to_json,
             'Authorization' => "Token #{auth_token}",
             'Content-Type' => 'application/json'

        expect_status(:unauthorized)
      end
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'failure' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctdl_query) { double('ctdl_query') } # rubocop:todo RSpec/VerifiedDoubles
      let(:error) { Faker::Lorem.sentence }

      before do
        # rubocop:todo RSpec/MessageSpies
        expect(CtdlQuery).to receive(:new) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          .at_least(:once).times
          .and_return(ctdl_query)

        # rubocop:todo RSpec/StubbedMock
        # rubocop:todo RSpec/MessageSpies
        expect(ctdl_query).to receive(:rows).and_raise(error) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
        # rubocop:enable RSpec/MessageSpies
        # rubocop:enable RSpec/StubbedMock
      end

      # rubocop:todo RSpec/MultipleExpectations
      it 'returns the error' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        # rubocop:enable RSpec/MultipleExpectations
        expect do
          # rubocop:todo Layout/LineLength
          post '/navy/ctdl?include_description_set_resources=yes&include_description_sets=yes&include_graph_data=yes&include_results_metadata=yes&order_by=search:recordUpdated&per_branch_limit=5&skip=100&take=20',
               # rubocop:enable Layout/LineLength
               query.to_json,
               'Authorization' => "Token #{auth_token}",
               'Content-Type' => 'application/json'
        end.to change(QueryLog, :count).by(1)

        expect_status(:internal_server_error)
        expect_json('error', error)

        query_log = QueryLog.last
        expect(query_log.completed_at).to be # rubocop:todo RSpec/Be
        expect(query_log.ctdl).to eq(query.to_json)
        expect(query_log.engine).to eq('ctdl')
        expect(query_log.error).to eq(error)
        expect(query_log.options['envelope_community_id']).to eq(navy.id)
        expect(query_log.options['include_description_set_resources']).to be(true)
        expect(query_log.options['include_description_sets']).to be(true)
        expect(query_log.options['include_graph_data']).to be(true)
        expect(query_log.options['include_results_metadata']).to be(true)
        expect(query_log.options['order_by']).to eq('search:recordUpdated')
        expect(query_log.options['per_branch_limit']).to eq(5)
        expect(query_log.options['skip']).to eq(100)
        expect(query_log.options['take']).to eq(20)
        expect(query_log.query).to be_nil
        expect(query_log.result).to be_nil
        expect(query_log.started_at).to be # rubocop:todo RSpec/Be
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'success' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:ctdl_query) { double('ctdl_query') } # rubocop:todo RSpec/VerifiedDoubles
      let(:ctid1) { Faker::Lorem.characters } # rubocop:todo RSpec/IndexedLet
      let(:ctid2) { Faker::Lorem.characters } # rubocop:todo RSpec/IndexedLet
      # rubocop:todo RSpec/IndexedLet
      let(:payload1) { JSON(Faker::Json.shallow_json).symbolize_keys }
      # rubocop:enable RSpec/IndexedLet
      # rubocop:todo RSpec/IndexedLet
      let(:payload2) { JSON(Faker::Json.shallow_json).symbolize_keys }
      # rubocop:enable RSpec/IndexedLet
      # rubocop:todo RSpec/IndexedLet
      let(:payload3) { JSON(Faker::Json.shallow_json).symbolize_keys }
      # rubocop:enable RSpec/IndexedLet
      let(:skip) { 0 }
      let(:sql) { Faker::Lorem.paragraph }
      let(:take) { 10 }
      let(:total_count) { rand(100..1_000) }

      before do
        allow(CtdlQuery).to receive(:new) do |*args|
          options = args.last
          expect(args.first).to eq(query) # rubocop:todo RSpec/ExpectInHook
          # rubocop:todo RSpec/ExpectInHook
          expect(options.fetch(:envelope_community)).to eq(envelope_community)
          # rubocop:enable RSpec/ExpectInHook
          # rubocop:todo RSpec/ExpectInHook
          expect(options.fetch(:project)).to eq(%i[@id ceterms:ctid payload])
          # rubocop:enable RSpec/ExpectInHook
          ctdl_query
        end

        allow(ctdl_query).to receive(:to_sql).and_return(sql)
      end

      # rubocop:todo RSpec/NestedGroups
      context 'without results metadata' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          allow(ctdl_query).to receive_messages(rows: [
                                                  {
                                                    '@id' => Faker::Internet.url,
                                                    'ceterms:ctid' => ctid1,
                                                    'payload' => payload1.to_json
                                                  },
                                                  {
                                                    '@id' => Faker::Internet.url,
                                                    'ceterms:ctid' => ctid2,
                                                    'payload' => payload2.to_json
                                                  },
                                                  {
                                                    '@id' => Faker::Internet.url,
                                                    'ceterms:ctid' => nil,
                                                    'payload' => payload3.to_json
                                                  }
                                                ], total_count: total_count)
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'default params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:envelope_community) { cer }

          # rubocop:todo RSpec/MultipleExpectations
          it 'returns query results with a total count' do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
            # rubocop:enable RSpec/MultipleExpectations
            expect do
              post '/ctdl',
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'
            end.to change(QueryLog, :count).by(1)

            expect_status(:ok)
            expect_json('data', [payload1, payload2, payload3])
            expect_json('total', total_count)
            expect_json('sql', nil)

            query_log = QueryLog.last
            expect(query_log.completed_at).to be # rubocop:todo RSpec/Be
            expect(query_log.ctdl).to eq(query.to_json)
            expect(query_log.engine).to eq('ctdl')
            expect(query_log.error).to be_nil
            expect(query_log.options['envelope_community_id']).to eq(cer.id)
            expect(query_log.options['include_description_set_resources']).to be(false)
            expect(query_log.options['include_description_sets']).to be(false)
            expect(query_log.options['include_graph_data']).to be(false)
            expect(query_log.options['include_results_metadata']).to be(false)
            expect(query_log.options['order_by']).to eq('^search:recordUpdated')
            expect(query_log.options['per_branch_limit']).to be_nil
            expect(query_log.options['skip']).to eq(0)
            expect(query_log.options['take']).to eq(10)
            expect(query_log.query).to eq(sql)
            expect(query_log.result).to eq(response.body)
            expect(query_log.started_at).to be # rubocop:todo RSpec/Be
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'custom params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:envelope_community) { navy }
          let(:skip) { 50 }
          let(:take) { 25 }

          it 'returns query results with a total count' do
            expect do
              post "/navy/ctdl?debug=yes&log=no&skip=#{skip}&take=#{take}",
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'
            end.not_to change(QueryLog, :count)

            expect_status(:ok)
            expect_json('data', [payload1, payload2, payload3])
            expect_json('total', total_count)
            expect_json('sql', sql)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/NestedGroups
        context 'with description sets' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:description_sets) do
            [JSON(Faker::Json.shallow_json).symbolize_keys]
          end

          let(:description_set_resources) do
            [JSON(Faker::Json.shallow_json).symbolize_keys]
          end

          let(:description_set_data) do
            [JSON(Faker::Json.shallow_json).symbolize_keys]
          end

          before do
            # rubocop:todo RSpec/StubbedMock
            # rubocop:todo RSpec/MessageSpies
            expect(FetchDescriptionSetData).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
              # rubocop:enable RSpec/MessageSpies
              # rubocop:enable RSpec/StubbedMock
              .with(
                [ctid1, ctid2],
                envelope_community: cer,
                include_graph_data: include_graph_data,
                include_resources: include_resources,
                per_branch_limit: per_branch_limit
              )
              .and_return(description_set_data)
          end

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'default params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:envelope_community) { cer }
            let(:include_graph_data) { false }
            let(:include_resources) { false }
            let(:per_branch_limit) { nil }

            before do
              # rubocop:todo RSpec/StubbedMock
              # rubocop:todo RSpec/MessageSpies
              # rubocop:todo RSpec/ExpectInHook
              expect(API::Entities::DescriptionSetData).to receive(:represent)
                # rubocop:enable RSpec/ExpectInHook
                # rubocop:enable RSpec/MessageSpies
                # rubocop:enable RSpec/StubbedMock
                .with(description_set_data)
                .and_return(description_sets: description_sets)
            end

            it 'returns query results with a total count and description sets' do
              post '/ce_registry/ctdl?include_description_sets=yes',
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'

              expect_status(:ok)
              expect_json('data', [payload1, payload2, payload3])
              expect_json('description_set_resources', nil)
              expect_json('description_sets', description_sets)
              expect_json('total', total_count)
              expect_json('sql', nil)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers

          # rubocop:todo RSpec/MultipleMemoizedHelpers
          # rubocop:todo RSpec/NestedGroups
          context 'custom params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
            # rubocop:enable RSpec/NestedGroups
            let(:envelope_community) { cer }
            let(:include_graph_data) { true }
            let(:include_resources) { true }
            let(:per_branch_limit) { 10 }

            before do
              # rubocop:todo RSpec/StubbedMock
              # rubocop:todo RSpec/MessageSpies
              # rubocop:todo RSpec/ExpectInHook
              expect(API::Entities::DescriptionSetData).to receive(:represent)
                # rubocop:enable RSpec/ExpectInHook
                # rubocop:enable RSpec/MessageSpies
                # rubocop:enable RSpec/StubbedMock
                .with(description_set_data)
                .and_return(
                  description_set_resources: description_set_resources,
                  description_sets: description_sets
                )
            end

            it 'returns query results with a total count and description sets' do
              # rubocop:todo Layout/LineLength
              post '/ctdl?debug=yes&include_description_set_resources=yes&include_description_sets=yes&include_graph_data=yes&per_branch_limit=10',
                   # rubocop:enable Layout/LineLength
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'

              expect_status(:ok)
              expect_json('data', [payload1, payload2, payload3])
              expect_json('description_set_resources', description_set_resources)
              expect_json('description_sets', description_sets)
              expect_json('total', total_count)
              expect_json('sql', sql)
            end
          end
          # rubocop:enable RSpec/MultipleMemoizedHelpers
        end

        # rubocop:todo RSpec/NestedGroups
        context 'with graph data' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:envelope_community) { cer }
          # rubocop:todo RSpec/IndexedLet
          let(:graph_resource1) { JSON(Faker::Json.shallow_json).symbolize_keys }
          # rubocop:enable RSpec/IndexedLet
          # rubocop:todo RSpec/IndexedLet
          let(:graph_resource2) { JSON(Faker::Json.shallow_json).symbolize_keys }
          # rubocop:enable RSpec/IndexedLet

          before do
            # rubocop:todo RSpec/StubbedMock
            # rubocop:todo RSpec/MessageSpies
            expect(FetchGraphResources).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
              # rubocop:enable RSpec/MessageSpies
              # rubocop:enable RSpec/StubbedMock
              .with([ctid1, ctid2], envelope_community: cer)
              .and_return([graph_resource1, graph_resource2])
          end

          # rubocop:todo RSpec/ExampleLength
          it 'returns query results with a total count and description sets' do
            post '/ce_registry/ctdl?include_graph_data=yes',
                 query.to_json,
                 'Authorization' => "Token #{auth_token}",
                 'Content-Type' => 'application/json'

            expect_status(:ok)
            expect_json('data', [payload1, payload2, payload3])
            expect_json(
              'description_set_resources',
              [graph_resource1, graph_resource2]
            )
            expect_json('description_sets', nil)
            expect_json('total', total_count)
            expect_json('sql', nil)
          end
          # rubocop:enable RSpec/ExampleLength
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'with results metadata' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:created_at1) { Faker::Time.backward(days: 365) } # rubocop:todo RSpec/IndexedLet
        let(:created_at2) { Faker::Time.backward(days: 365) } # rubocop:todo RSpec/IndexedLet
        let(:envelope_community) { navy }
        let(:owner1) { SecureRandom.uuid } # rubocop:todo RSpec/IndexedLet
        let(:owner2) { SecureRandom.uuid } # rubocop:todo RSpec/IndexedLet
        let(:publisher1) { SecureRandom.uuid } # rubocop:todo RSpec/IndexedLet
        let(:publisher2) { SecureRandom.uuid } # rubocop:todo RSpec/IndexedLet
        let(:resource_uri1) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
        let(:resource_uri2) { Faker::Internet.url } # rubocop:todo RSpec/IndexedLet
        let(:updated_at1) { Faker::Time.backward(days: 30) } # rubocop:todo RSpec/IndexedLet
        let(:updated_at2) { Faker::Time.backward(days: 30) } # rubocop:todo RSpec/IndexedLet

        before do
          allow(ctdl_query).to receive_messages(rows: [
                                                  {
                                                    '@id' => resource_uri1,
                                                    'ceterms:ctid' => ctid1,
                                                    'payload' => payload1.to_json,
                                                    'search:recordCreated' => created_at1,
                                                    'search:recordOwnedBy' => owner1,
                                                    'search:recordPublishedBy' => publisher1,
                                                    'search:recordUpdated' => updated_at1
                                                  },
                                                  {
                                                    '@id' => resource_uri2,
                                                    'ceterms:ctid' => ctid2,
                                                    'payload' => payload2.to_json,
                                                    'search:recordCreated' => created_at2,
                                                    'search:recordOwnedBy' => owner2,
                                                    'search:recordPublishedBy' => publisher2,
                                                    'search:recordUpdated' => updated_at2
                                                  }
                                                ], total_count: total_count)
        end

        it 'returns query results with metadata' do # rubocop:todo RSpec/ExampleLength
          expect do
            post '/navy/ctdl?debug=no&include_results_metadata=yes&log=no',
                 query.to_json,
                 'Authorization' => "Token #{auth_token}",
                 'Content-Type' => 'application/json'
          end.not_to change(QueryLog, :count)

          expect_status(:ok)
          expect_json('data', [payload1, payload2])
          expect_json('total', total_count)
          expect_json('sql', nil)
          expect_json('results_metadata.0.resource_uri', resource_uri1)
          expect_json('results_metadata.0.search:recordCreated', created_at1.as_json)
          expect_json('results_metadata.0.search:recordOwnedBy', owner1)
          expect_json('results_metadata.0.search:recordPublishedBy', publisher1)
          expect_json('results_metadata.0.search:recordUpdated', updated_at1.as_json)
          expect_json('results_metadata.1.resource_uri', resource_uri2)
          expect_json('results_metadata.1.search:recordCreated', created_at2.as_json)
          expect_json('results_metadata.1.search:recordOwnedBy', owner2)
          expect_json('results_metadata.1.search:recordPublishedBy', publisher2)
          expect_json('results_metadata.1.search:recordUpdated', updated_at2.as_json)
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
