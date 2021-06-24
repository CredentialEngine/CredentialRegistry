require_relative 'shared_examples/missing_envelope'
require_relative 'shared_examples/signed_endpoint'
require 'query_log'

RSpec.describe API::V1::Sparql do
  before { VCR.turn_off! }
  after { VCR.turn_on! }

  context 'POST /sparql' do
    let(:token) { create(:auth_token, :admin) }
    let(:sparql_query) {
      {
        "query" => %{
          PREFIX credreg: <https://credreg.net/>
          PREFIX ceterms: <https://purl.org/ctdl/terms/>
          PREFIX ceasn: <https://purl.org/ctdlasn/terms/>
          SELECT ?totalResults ?id ?searchResultPayload
          WITH { SELECT DISTINCT ?id ?searchResultPayload
            WHERE {
              <http://aws.amazon.com/neptune/vocab/v01/QueryHints#Query>
              <http://aws.amazon.com/neptune/vocab/v01/QueryHints#joinOrder> 'Ordered' . FILTER EXISTS {
                ?id ceterms:ctid ?anyValue . } { { ?id ( a ) ?layer_1 FILTER(?layer_1 IN(ceterms:Certificate) ) . } }
                ?id credreg:__payload ?searchResultPayload .
              }
            }
            AS %mainQuery WHERE { { SELECT (COUNT(DISTINCT(?id)) AS ?totalResults)
              WHERE { INCLUDE %mainQuery } } UNION { SELECT ?id ?searchResultPayload
                WHERE { INCLUDE %mainQuery } ORDER BY DESC(?id) OFFSET 0 LIMIT 5 } }
                ORDER BY DESC(?id)",
                "include_description_sets
        },
        "include_description_sets" => false,
        "include_description_set_resources" => false,
        "_ctdl" => {
          "Query" => {
            "@type" => "ceterms:Certificate",
            "ceterms:name"=>"accounting"
          },
          "Skip" => 0,
          "Take" => 5,
          "OrderBy" => "Default",
          "IncludeDebugInfo" => true,
          "DescriptionSetType" => "Resource",
          "DescriptionSetRelatedURIsLimit" => 50,
          "ExtraLoggingInfo" => {"Source" => "CredReg/QueryHelper", "ClientIP" => "162.250.2.19"}
        },
        "_query_logic" => {
          "Operator" => "AND",
          "Nodes" => [{"Subject" => "?id",
          "Predicate" => "@type",
          "Value" => ["ceterms:Certificate"],
          "Nodes" => []}]
        },
        "per_branch_limit" => 50
      }
    }

    context 'without logging' do
      it "doesn't log successful queries" do
        stub_request(:post, "#{ENV.fetch('NEPTUNE_ENDPOINT')}/sparql")
          .to_return(body: { test: 'success' }.to_json)

        expect {
          post '/sparql?log=false',
               sparql_query.to_json,
               'Authorization' => "Token #{token.value}",
               'Content-Type' => 'application/json'
        }.not_to change { QueryLog.count }

        expect_status(:ok)
      end

      it "doesn't log failed queries" do
        stub_request(:post, "#{ENV.fetch('NEPTUNE_ENDPOINT')}/sparql")
          .to_return(status: [500, 'Internal Server Error'])

        expect {
          post '/sparql?log=no',
               sparql_query.to_json,
               'Authorization' => "Token #{token.value}",
               'Content-Type' => 'application/json'
        }.not_to change { QueryLog.count }

        expect_status(:internal_server_error)
      end
    end

    context 'with logging' do
      it 'logs successful queries' do
        stub_request(:post, "#{ENV.fetch('NEPTUNE_ENDPOINT')}/sparql").to_return(body: { test: "success" }.to_json)
        post '/sparql', sparql_query.to_json, { 'Authorization' => "Token #{token.value}", "CONTENT_TYPE" => "application/json" }
        expect_status(:ok)
        expect(QueryLog.count).to eq(1)

        query_log = QueryLog.first
        expect(query_log.ctdl).to eq(sparql_query['_ctdl'].to_json)
        expect(query_log.query).to eq(sparql_query['query'])
        expect(query_log.result).to eq({ "test" => "success" }.to_json)
        expect(query_log.error).to be_nil
        expect(query_log.started_at).not_to be_nil
        expect(query_log.completed_at).not_to be_nil
      end

      it 'logs failed queries' do
        stub_request(:post, "#{ENV.fetch('NEPTUNE_ENDPOINT')}/sparql").to_return(status: [ 500, "Internal Server Error" ])
        post '/sparql', sparql_query.to_json, { 'Authorization' => "Token #{token.value}", "CONTENT_TYPE" => "application/json" }
        expect_status(500)
        expect(QueryLog.count).to eq(1)

        query_log = QueryLog.first
        expect(query_log.ctdl).to eq(sparql_query['_ctdl'].to_json)
        expect(query_log.query).to eq(sparql_query['query'])
        expect(query_log.result).to eq(nil)
        expect(query_log.error).not_to be_nil
        expect(query_log.started_at).not_to be_nil
        expect(query_log.completed_at).not_to be_nil
      end
    end
  end
end
