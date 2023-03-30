require 'spec_helper'

RSpec.describe API::V1::DescriptionSets do
  describe 'GET /description_sets/:ctid' do
    let(:ctid1) { Envelope.generate_ctid }
    let(:ctid2) { Envelope.generate_ctid }
    let(:user) { create(:user) }

    let!(:community) do
      create(:envelope_community,
        name: "ce_registry",
        default: true,
      )
    end

    let!(:description_set1) do
      create(
        :description_set,
        envelope_community: community,
        ceterms_ctid: ctid1,
        path: '> ceasn:creator > ceterms:Agent',
        uris: 8.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set2) do
      create(
        :description_set,
        envelope_community: community,
        ceterms_ctid: ctid1,
        path: '> ceasn:publicationStatusType > skos:Concept',
        uris: 5.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set3) do
      create(
        :description_set,
        envelope_community: community,
        ceterms_ctid: ctid2,
        path: '> ceasn:alignTo > ceasn:CompetencyFramework',
        uris: 3.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set4) do
      create(
        :description_set,
        envelope_community: community,
        ceterms_ctid: ctid2,
        path: '< ceasn:isPartOf < ceasn:Competency',
        uris: 2.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set5) do
      create(
        :description_set,
        envelope_community: community,
        ceterms_ctid: ctid2,
        path: '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept',
        uris: [Faker::Internet.url]
      )
    end

    context 'no params' do
      before do
        get "/description_sets/#{ctid1}",
            'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns fall URIs at all paths for the given CTID' do
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(2)
        expect_json('0.path', '> ceasn:creator > ceterms:Agent')
        expect_json('0.total', 8)
        expect_json('0.uris', description_set1.uris)
        expect_json('1.path', '> ceasn:publicationStatusType > skos:Concept')
        expect_json('1.total', 5)
        expect_json('1.uris', description_set2.uris)

      end
    end

    context 'with limit' do
      before do
        get "/description_sets/#{ctid2}?limit=2",
            'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns limited URIs at all paths for the given CTID' do
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(3)
        expect_json('0.path', '< ceasn:isPartOf < ceasn:Competency')
        expect_json('0.total', 2)
        expect_json('0.uris', description_set4.uris)
        expect_json('1.path', '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept')
        expect_json('1.total', 1)
        expect_json('1.uris', description_set5.uris)
        expect_json('2.path', '> ceasn:alignTo > ceasn:CompetencyFramework')
        expect_json('2.total', 3)
        expect_json('2.uris', description_set3.uris.first(2))
      end
    end

    context 'with path_contains' do
      before do
        get "/description_sets/#{ctid1}?path_contains=concept",
            'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns all URIs at partially matched paths for the given CTID' do
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(1)
        expect_json('0.path', '> ceasn:publicationStatusType > skos:Concept')
        expect_json('0.total', 5)
        expect_json('0.uris', description_set2.uris)
      end
    end

    context 'with path_exact' do
      before do
        get "/description_sets/#{ctid2}?path_exact=%3C+ceasn%3Aispartof+%3C+ceasn%3Acompetency",
            'Authorization' => "Token #{user.auth_token.value}"
      end

      it 'returns all URIs at fully matched paths for the given CTID' do
        expect_status(:ok)
        expect_json_types(:array)
        expect_json_sizes(1)
        expect_json('0.path', '< ceasn:isPartOf < ceasn:Competency')
        expect_json('0.total', 2)
        expect_json('0.uris', description_set4.uris)
      end
    end
  end

  describe 'POST /description_sets' do
    let(:ctid1) { Envelope.generate_ctid }
    let(:ctid2) { Envelope.generate_ctid }
    let(:id1) { Faker::Lorem.characters }
    let(:id2) { Faker::Lorem.characters }
    let(:id3) { Faker::Lorem.characters }
    let(:id4) { Faker::Lorem.characters }
    let(:id5) { Faker::Lorem.characters }
    let(:id6) { Faker::Lorem.characters }
    let(:id7) { Faker::Lorem.characters }
    let(:id8) { Faker::Lorem.characters }
    let(:uri1) { "https://credentialengineregistry.org/resources/#{id1}" }
    let(:uri2) { "https://credentialengineregistry.org/resources/#{id2}" }
    let(:uri3) { "https://credentialengineregistry.org/resources/#{id3}" }
    let(:uri4) { "https://credentialengineregistry.org/resources/#{id4}" }
    let(:uri5) { "https://credreg.net/bnodes/#{id5}" }
    let(:uri6) { "https://credreg.net/bnodes/#{id6}" }
    let(:uri7) { "https://credreg.net/bnodes/#{id7}" }
    let(:uri8) { "https://credreg.net/bnodes/#{id8}" }
    let(:user) { create(:user) }

    let!(:description_set1) do
      create(
        :description_set,
        ceterms_ctid: ctid1,
        path: '> ceasn:creator > ceterms:Agent',
        uris: [uri1, uri2, uri3, uri4, uri5, uri6, uri7, uri8]
      )
    end

    let!(:description_set2) do
      create(
        :description_set,
        ceterms_ctid: ctid1,
        path: '> ceasn:publicationStatusType > skos:Concept',
        uris: [uri1, uri2, uri3, uri4, uri5]
      )
    end

    let!(:description_set3) do
      create(
        :description_set,
        ceterms_ctid: ctid2,
        path: '> ceasn:alignTo > ceasn:CompetencyFramework',
        uris: [uri1, uri2, uri3]
      )
    end

    let!(:description_set4) do
      create(
        :description_set,
        ceterms_ctid: ctid2,
        path: '< ceasn:isPartOf < ceasn:Competency',
        uris: [uri1, uri2]
      )
    end

    let!(:description_set5) do
      create(
        :description_set,
        ceterms_ctid: ctid2,
        path: '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept',
        uris: [uri1]
      )
    end

    let!(:resource1) { create(:envelope_resource, resource_id: ctid1) }
    let!(:resource2) { create(:envelope_resource, resource_id: ctid2) }

    before do
      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: id1
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: id2
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: id3
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: id4
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: "_:#{id5}"
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: "_:#{id6}"
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: "_:#{id7}"
      )

      create(
        :envelope_resource,
        processed_resource: JSON(Faker::Json.shallow_json),
        resource_id: "_:#{id8}"
      )
    end

    context 'without subresources' do
      context 'no optional params' do
        before do
          post "/description_sets",
               { ctids: [ctid1] },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(2)
          expect_json('data', [resource1.processed_resource.deep_symbolize_keys])
          expect_json('description_sets.0.ctid', ctid1)
          expect_json(
            'description_sets.0.description_set.0.path',
            '> ceasn:creator > ceterms:Agent'
          )
          expect_json('description_sets.0.description_set.0.total', 8)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set1.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '> ceasn:publicationStatusType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 5)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set2.uris
          )
        end
      end

      context 'with limit' do
        before do
          post "/description_sets",
               { ctids: [ctid2], include_graph_data: true, per_branch_limit: 2 },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns limited URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(3)
          expect_json('data', [resource2.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 0)
          expect_json('description_sets.0.ctid', ctid2)
          expect_json(
            'description_sets.0.description_set.0.path',
            '< ceasn:isPartOf < ceasn:Competency'
          )
          expect_json('description_sets.0.description_set.0.total', 2)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set4.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 1)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set5.uris
          )
          expect_json(
            'description_sets.0.description_set.2.path',
            '> ceasn:alignTo > ceasn:CompetencyFramework'
          )
          expect_json('description_sets.0.description_set.2.total', 3)
          expect_json(
            'description_sets.0.description_set.2.uris',
            description_set3.uris.first(2)
          )
        end
      end

      context 'with path_contains' do
        before do
          post "/description_sets",
               { ctids: [ctid1], path_contains: 'concept' },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at partially matched paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(2)
          expect_json('data', [resource1.processed_resource.deep_symbolize_keys])
          expect_json('description_sets.0.ctid', ctid1)
          expect_json(
            'description_sets.0.description_set.0.path',
            '> ceasn:publicationStatusType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.0.total', 5)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set2.uris
          )
        end
      end

      context 'with path_exact' do
        before do
          post "/description_sets",
               {
                 ctids: [ctid2],
                 path_exact: '< ceasn:ispartof < ceasn:competency'
               },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at fully matched paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(2)
          expect_json('data', [resource2.processed_resource.deep_symbolize_keys])
          expect_json('description_sets.0.ctid', ctid2)
          expect_json(
            'description_sets.0.description_set.0.path',
            '< ceasn:isPartOf < ceasn:Competency'
          )
          expect_json('description_sets.0.description_set.0.total', 2)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set4.uris
          )
        end
      end
    end

    context 'with graph data' do
      context 'no optional params' do
        before do
          post "/description_sets",
               { ctids: [ctid1], include_graph_data: true },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(3)
          expect_json('data', [resource1.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 0)
          expect_json('description_sets.0.ctid', ctid1)
          expect_json(
            'description_sets.0.description_set.0.path',
            '> ceasn:creator > ceterms:Agent'
          )
          expect_json('description_sets.0.description_set.0.total', 8)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set1.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '> ceasn:publicationStatusType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 5)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set2.uris
          )
        end
      end

      context 'with limit' do
        before do
          post "/description_sets",
               { ctids: [ctid2], include_graph_data: true, per_branch_limit: 2 },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns limited URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(3)
          expect_json('data', [resource2.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 0)
          expect_json('description_sets.0.ctid', ctid2)
          expect_json(
            'description_sets.0.description_set.0.path',
            '< ceasn:isPartOf < ceasn:Competency'
          )
          expect_json('description_sets.0.description_set.0.total', 2)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set4.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 1)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set5.uris
          )
          expect_json(
            'description_sets.0.description_set.2.path',
            '> ceasn:alignTo > ceasn:CompetencyFramework'
          )
          expect_json('description_sets.0.description_set.2.total', 3)
          expect_json(
            'description_sets.0.description_set.2.uris',
            description_set3.uris.first(2)
          )
        end
      end
    end

    context 'with resources' do
      context 'no optional params' do
        before do
          post "/description_sets",
               { ctids: [ctid1], include_resources: true },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(3)
          expect_json('data', [resource1.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 8)
          expect_json('description_sets.0.ctid', ctid1)
          expect_json(
            'description_sets.0.description_set.0.path',
            '> ceasn:creator > ceterms:Agent'
          )
          expect_json('description_sets.0.description_set.0.total', 8)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set1.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '> ceasn:publicationStatusType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 5)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set2.uris
          )
        end
      end

      context 'with limit' do
        before do
          post "/description_sets",
               { ctids: [ctid2], include_resources: true, per_branch_limit: 2 },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns limited URIs at all paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(3)
          expect_json('data', [resource2.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 2)
          expect_json('description_sets.0.ctid', ctid2)
          expect_json(
            'description_sets.0.description_set.0.path',
            '< ceasn:isPartOf < ceasn:Competency'
          )
          expect_json('description_sets.0.description_set.0.total', 2)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set4.uris
          )
          expect_json(
            'description_sets.0.description_set.1.path',
            '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.1.total', 1)
          expect_json(
            'description_sets.0.description_set.1.uris',
            description_set5.uris
          )
          expect_json(
            'description_sets.0.description_set.2.path',
            '> ceasn:alignTo > ceasn:CompetencyFramework'
          )
          expect_json('description_sets.0.description_set.2.total', 3)
          expect_json(
            'description_sets.0.description_set.2.uris',
            description_set3.uris.first(2)
          )
        end
      end

      context 'with path_contains' do
        before do
          post "/description_sets",
               {
                 ctids: [ctid1],
                 include_graph_data: true,
                 include_resources: true,
                 include_results_metadata: true,
                 path_contains: 'concept'
               },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at partially matched paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(4)
          expect_json('data', [resource1.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 5)
          expect_json_sizes(results_metadata: 1)
          expect_json('description_sets.0.ctid', ctid1)
          expect_json(
            'description_sets.0.description_set.0.path',
            '> ceasn:publicationStatusType > skos:Concept'
          )
          expect_json('description_sets.0.description_set.0.total', 5)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set2.uris
          )
        end
      end

      context 'with path_exact' do
        before do
          post "/description_sets",
               {
                 ctids: [ctid2],
                 include_resources: true,
                 include_results_metadata: true,
                 path_exact: '< ceasn:ispartof < ceasn:competency'
               },
               'Authorization' => "Token #{user.auth_token.value}"
        end

        it 'returns all URIs at fully matched paths for the given CTID' do
          expect_status(:ok)
          expect_json_sizes(4)
          expect_json('data', [resource2.processed_resource.deep_symbolize_keys])
          expect_json_sizes(description_set_resources: 2)
          expect_json_sizes(results_metadata: 1)
          expect_json('description_sets.0.ctid', ctid2)
          expect_json(
            'description_sets.0.description_set.0.path',
            '< ceasn:isPartOf < ceasn:Competency'
          )
          expect_json('description_sets.0.description_set.0.total', 2)
          expect_json(
            'description_sets.0.description_set.0.uris',
            description_set4.uris
          )
        end
      end
    end
  end

  context "with community" do
    let(:user) { create(:user) }

    let!(:community_1) do
      create(:envelope_community,
        name: "learning_tapestry_test",
      )
    end

    let!(:community_2) do
      create(:envelope_community,
        name: "ce_registry",
      )
    end

    let!(:description_set_1) do
      create(
        :description_set,
        envelope_community: community_1,
      )
    end

    let!(:description_set_2) do
      create(
        :description_set,
        envelope_community: community_2,
      )
    end

    describe "GET /description_sets/:ctid" do
      before do
        get "%s/description_sets/%s" % [request_community_name, request_ctid],
          "Authorization" => "Token #{user.auth_token.value}"
      end

      context "with matching community name and ctid" do
        let!(:other_community_description_set) do
          create(
            :description_set,
            ceterms_ctid: description_set_2.ceterms_ctid,
            envelope_community: community_1,
          )
        end

        let(:request_community_name) do
          community_2.name
        end

        let(:request_ctid) do
          description_set_2.ceterms_ctid
        end

        it "returns description set from requested community" do
          expect_json_types(:array)
          expect_json_sizes(1)
          expect_json("0.path", description_set_2.path)
        end
      end

      context "with not matching community name and ctid" do
        let(:request_community_name) do
          community_2.name
        end

        let(:request_ctid) do
          description_set_1.ceterms_ctid
        end

        it "doesn't return any description sets" do
          expect_json_types(:array)
          expect_json_sizes(0)
        end
      end
    end

    describe "POST /:community_name/description_sets" do
      before do
        post "%s/description_sets" % request_community_name,
          { ctids: [request_ctid] },
          "Authorization" => "Token #{user.auth_token.value}"
      end

      context "with matching community name and ctid" do
        let!(:other_community_description_set) do
          create(
            :description_set,
            ceterms_ctid: description_set_2.ceterms_ctid,
            envelope_community: community_1,
          )
        end

        let(:request_community_name) do
          community_2.name
        end

        let(:request_ctid) do
          description_set_2.ceterms_ctid
        end

        it "returns description set from requested community" do
          expect_json_sizes(description_sets: 1)
          expect_json('description_sets.0.ctid', description_set_2.ceterms_ctid)
          expect_json(
            "description_sets.0.description_set.0.path",
            description_set_2.path,
          )
        end
      end

      context "with not matching community name and ctid" do
        let(:request_community_name) do
          community_2.name
        end

        let(:request_ctid) do
          description_set_1.ceterms_ctid
        end

        it "doesn't return any description sets" do
          expect_json_sizes(description_sets: 0)
        end
      end
    end
  end
end
