require_relative '../../app/services/graph_search'
require_relative '../../app/models/query_condition'

describe GraphSearch, type: :service do
  before(:all) do
    reset_neo4j
    import_into_neo4j('../../support/fixtures/json/ce_registry/credential/2_valid.json')
    import_into_neo4j('../../support/fixtures/json/ce_registry/credential/3_valid.json')
  end

  describe '#organizations' do
    let(:graph_search) { GraphSearch.new }

    it 'returns organizations according to the some conditions' do
      conditions = [QueryCondition.new(object: 'Credential',
                                       element: 'renewal/name',
                                       value: 'Health Informatics'),
                    QueryCondition.new(element: 'type', value: 'QACredentialOrganization'),
                    QueryCondition.new(element: 'fein', value: '23-7455576')]

      organizations = graph_search.organizations(conditions)

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana University Bloomington')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Credential',
                                       element: 'renewal/name',
                                       value: 'WRONG VALUE')]

      organizations = graph_search.organizations(conditions)

      expect(organizations).to be_empty
    end

    it 'filters organizations according to the roles' do
      roles = %w[OFFERED REVOKED]

      organizations = graph_search.organizations([], roles)

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:name]).to eq('Indiana University Bloomington')
    end
  end

  describe '#credentials' do
    let(:graph_search) { GraphSearch.new }

    it 'returns credentials according to the some conditions' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'address/addressLocality',
                                       value: 'Big Rapids'),
                    QueryCondition.new(element: 'type', value: 'Certification')]

      credentials = graph_search.credentials(conditions)

      expect(credentials.size).to eq(1)
      expect(credentials.last.props[:type]).to eq('Certification')
      expect(credentials.last.props[:name]).to eq('Health Informatics')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'address/addressLocality',
                                       value: 'WRONG VALUE')]

      credentials = graph_search.credentials(conditions)

      expect(credentials).to be_empty
    end

    it 'filters organizations according to the roles' do
      roles = %w[OFFERED REVOKED]

      credentials = graph_search.credentials([], roles)

      expect(credentials.size).to eq(1)
      expect(credentials.last.props[:name]).to eq('Health Informatics')
    end
  end
end
