require 'spec_helper'

RSpec.describe API::V1::DescriptionSets do
  describe 'GET /description_sets/:ctid' do
    let(:ctid1) { Envelope.generate_ctid }
    let(:ctid2) { Envelope.generate_ctid }
    let(:user) { create(:user) }

    let!(:description_set1) do
      create(
        :description_set,
        ceterms_ctid: ctid1,
        path: '> ceasn:creator > ceterms:Agent',
        uris: 8.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set2) do
      create(
        :description_set,
        ceterms_ctid: ctid1,
        path: '> ceasn:publicationStatusType > skos:Concept',
        uris: 5.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set3) do
      create(
        :description_set,
        ceterms_ctid: ctid2,
        path: '> ceasn:alignTo > ceasn:CompetencyFramework',
        uris: 3.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set4) do
      create(
        :description_set,
        ceterms_ctid: ctid2,
        path: '< ceasn:isPartOf < ceasn:Competency',
        uris: 2.times.map { Faker::Internet.url }
      )
    end

    let!(:description_set5) do
      create(
        :description_set,
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
        expect_json('0.path', '> ceasn:alignTo > ceasn:CompetencyFramework')
        expect_json('0.total', 3)
        expect_json('0.uris', description_set3.uris.first(2))
        expect_json('1.path', '< ceasn:isPartOf < ceasn:Competency')
        expect_json('1.total', 2)
        expect_json('1.uris', description_set4.uris)
        expect_json('2.path', '< ceasn:isPartOf < ceasn:Competency > ceasn:educationLevelType > skos:Concept')
        expect_json('2.total', 1)
        expect_json('2.uris', description_set5.uris)
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
end
