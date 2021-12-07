require 'spec_helper'

RSpec.describe API::V1::Ctdl do
  context 'POST /ctdl' do
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

    context 'invalid token' do
      let(:auth_token) { Faker::Lorem.characters }

      it 'returns a 401' do
        post '/ctdl',
             query.to_json,
             'Authorization' => "Token #{auth_token}",
             'Content-Type' => 'application/json'

        expect_status(:unauthorized)
      end
    end

    context 'failure' do
      let(:ctdl_query) { double('ctdl_query') }
      let(:error) { Faker::Lorem.sentence }

      before do
        expect(CtdlQuery).to receive(:new)
          .at_least(:once).times
          .and_return(ctdl_query)

        expect(ctdl_query).to receive(:execute).and_raise(error)
      end

      it 'returns the error' do
        expect {
          post '/navy/ctdl?include_description_set_resources=yes&include_description_sets=yes&include_graph_data=yes&include_results_metadata=yes&order_by=search:recordUpdated&per_branch_limit=5&skip=100&take=20',
               query.to_json,
               'Authorization' => "Token #{auth_token}",
               'Content-Type' => 'application/json'
        }.to change { QueryLog.count }.by(1)

        expect_status(:internal_server_error)
        expect_json('error', error)

        query_log = QueryLog.last
        expect(query_log.completed_at).to be
        expect(query_log.ctdl).to eq(query.to_json)
        expect(query_log.engine).to eq('ctdl')
        expect(query_log.error).to eq(error)
        expect(query_log.options['envelope_community_id']).to eq(navy.id)
        expect(query_log.options['include_description_set_resources']).to eq(true)
        expect(query_log.options['include_description_sets']).to eq(true)
        expect(query_log.options['include_graph_data']).to eq(true)
        expect(query_log.options['include_results_metadata']).to eq(true)
        expect(query_log.options['order_by']).to eq('search:recordUpdated')
        expect(query_log.options['per_branch_limit']).to eq(5)
        expect(query_log.options['skip']).to eq(100)
        expect(query_log.options['take']).to eq(20)
        expect(query_log.query).to eq(nil)
        expect(query_log.result).to eq(nil)
        expect(query_log.started_at).to be
      end
    end

    context 'success' do
      let(:count) { rand(100..1_000) }
      let(:count_query) { double('count_query') }
      let(:ctid1) { Faker::Lorem.characters }
      let(:ctid2) { Faker::Lorem.characters }
      let(:data_query) { double('data_query') }
      let(:payload1) { JSON(Faker::Json.shallow_json).symbolize_keys }
      let(:payload2) { JSON(Faker::Json.shallow_json).symbolize_keys }
      let(:payload3) { JSON(Faker::Json.shallow_json).symbolize_keys }
      let(:skip) { 0 }
      let(:sql) { Faker::Lorem.paragraph }
      let(:take) { 10 }

      before do
        allow(CtdlQuery).to receive(:new) do |*args|
          options = args.last

          expect(args.first).to eq(query)
          expect(options.fetch(:envelope_community)).to eq(envelope_community)

          case (projection = options.fetch(:project))
          when 'COUNT(*) AS count'
            expect(options.key?(:skip)).to eq(false)
            expect(options.key?(:take)).to eq(false)
            count_query
          when %w["@id" "ceterms:ctid" payload]
            expect(options.fetch(:skip)).to eq(skip)
            expect(options.fetch(:take)).to eq(take)
            data_query
          else
            raise "Unexpected projection: #{projection}"
          end
        end

        allow(count_query).to receive(:execute)
          .and_return([{ 'count' => count }])

        allow(data_query).to receive(:to_sql).and_return(sql)
      end

      context 'without results metadata' do
        before do
          allow(data_query).to receive(:execute)
            .and_return([
              { 'payload' => payload1.to_json, 'ceterms:ctid' => ctid1 },
              { 'payload' => payload2.to_json, 'ceterms:ctid' => ctid2 },
              { 'payload' => payload3.to_json, 'ceterms:ctid' => nil }
            ])
        end

        context 'default params' do
          let(:envelope_community) { cer }

          it 'returns query results with a total count' do
            expect {
              post '/ctdl',
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'
            }.to change { QueryLog.count }.by(1)

            expect_status(:ok)
            expect_json('data', [payload1, payload2, payload3])
            expect_json('total', count)
            expect_json('sql', nil)

            query_log = QueryLog.last
            expect(query_log.completed_at).to be
            expect(query_log.ctdl).to eq(query.to_json)
            expect(query_log.engine).to eq('ctdl')
            expect(query_log.error).to eq(nil)
            expect(query_log.options['envelope_community_id']).to eq(cer.id)
            expect(query_log.options['include_description_set_resources']).to eq(false)
            expect(query_log.options['include_description_sets']).to eq(false)
            expect(query_log.options['include_graph_data']).to eq(false)
            expect(query_log.options['include_results_metadata']).to eq(false)
            expect(query_log.options['order_by']).to eq('^search:relevance')
            expect(query_log.options['per_branch_limit']).to eq(nil)
            expect(query_log.options['skip']).to eq(0)
            expect(query_log.options['take']).to eq(10)
            expect(query_log.query).to eq(sql)
            expect(query_log.result).to eq(response.body)
            expect(query_log.started_at).to be
          end
        end

        context 'custom params' do
          let(:envelope_community) { navy }
          let(:skip) { 50 }
          let(:take) { 25 }

          it 'returns query results with a total count' do
            expect {
              post "/navy/ctdl?debug=yes&log=no&skip=#{skip}&take=#{take}",
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'
            }.not_to change { QueryLog.count }

            expect_status(:ok)
            expect_json('data', [payload1, payload2, payload3])
            expect_json('total', count)
            expect_json('sql', sql)
          end
        end

        context 'with description sets' do
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
            expect(FetchDescriptionSetData).to receive(:call)
              .with(
                [ctid1, ctid2],
                include_graph_data: include_graph_data,
                include_resources: include_resources,
                per_branch_limit: per_branch_limit
              )
              .and_return(description_set_data)
          end

          context 'default params' do
            let(:envelope_community) { cer }
            let(:include_graph_data) { false }
            let(:include_resources) { false }
            let(:per_branch_limit) { nil }

            before do
              expect(API::Entities::DescriptionSetData).to receive(:represent)
                .with(description_set_data)
                .and_return(description_sets: description_sets)
            end

            it 'returns query results with a total count and description sets' do
              post "/ce_registry/ctdl?include_description_sets=yes",
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'

              expect_status(:ok)
              expect_json('data', [payload1, payload2, payload3])
              expect_json('description_set_resources', nil)
              expect_json('description_sets', description_sets)
              expect_json('total', count)
              expect_json('sql', nil)
            end
          end

          context 'custom params' do
            let(:envelope_community) { cer }
            let(:include_graph_data) { true }
            let(:include_resources) { true }
            let(:per_branch_limit) { 10 }

            before do
              expect(API::Entities::DescriptionSetData).to receive(:represent)
                .with(description_set_data)
                .and_return(
                  description_set_resources: description_set_resources,
                  description_sets: description_sets
                )
            end

            it 'returns query results with a total count and description sets' do
              post "/ctdl?debug=yes&include_description_set_resources=yes&include_description_sets=yes&include_graph_data=yes&per_branch_limit=10",
                   query.to_json,
                   'Authorization' => "Token #{auth_token}",
                   'Content-Type' => 'application/json'

              expect_status(:ok)
              expect_json('data', [payload1, payload2, payload3])
              expect_json('description_set_resources', description_set_resources)
              expect_json('description_sets', description_sets)
              expect_json('total', count)
              expect_json('sql', sql)
            end
          end
        end

        context 'with graph data' do
          let(:envelope_community) { cer }
          let(:graph_resource1) { JSON(Faker::Json.shallow_json).symbolize_keys }
          let(:graph_resource2) { JSON(Faker::Json.shallow_json).symbolize_keys }

          before do
            expect(FetchGraphResources).to receive(:call)
              .with([ctid1, ctid2])
              .and_return([graph_resource1, graph_resource2])
          end

          it 'returns query results with a total count and description sets' do
            post "/ce_registry/ctdl?include_graph_data=yes",
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
            expect_json('total', count)
            expect_json('sql', nil)
          end
        end
      end

      context 'with results metadata' do
        let(:created_at1) { Faker::Time.backward(days: 365) }
        let(:created_at2) { Faker::Time.backward(days: 365) }
        let(:envelope_community) { navy }
        let(:owner1) { SecureRandom.uuid }
        let(:owner2) { SecureRandom.uuid }
        let(:publisher1) { SecureRandom.uuid }
        let(:publisher2) { SecureRandom.uuid }
        let(:resource_uri1) { Faker::Internet.url }
        let(:resource_uri2) { Faker::Internet.url }
        let(:updated_at1) { Faker::Time.backward(days: 30) }
        let(:updated_at2) { Faker::Time.backward(days: 30) }

        before do
          allow(data_query).to receive(:execute)
            .and_return([
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
            ])
        end

        it 'returns query results with metadata' do
          expect {
            post "/navy/ctdl?debug=no&include_results_metadata=yes&log=no",
                 query.to_json,
                 'Authorization' => "Token #{auth_token}",
                 'Content-Type' => 'application/json'
          }.not_to change { QueryLog.count }

          expect_status(:ok)
          expect_json('data', [payload1, payload2])
          expect_json('total', count)
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
  end
end
