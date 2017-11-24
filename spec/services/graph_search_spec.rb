require_relative '../../app/services/graph_search'

describe GraphSearch, type: :service do
  before(:all) do
    reset_neo4j
    import_into_neo4j('../../support/fixtures/json/ce_registry/credential/2_valid.json')
  end

  describe '#organizations' do
    let(:graph_search) { GraphSearch.new }

    it 'returns organizations according to the some conditions' do
      conditions = [OpenStruct.new(object: 'Credential',
                                   element: 'renewal/name',
                                   value: 'Health Informatics'),
                    OpenStruct.new(element: 'type', value: 'QACredentialOrganization'),
                    OpenStruct.new(element: 'fein', value: '23-7455576')]

      organizations = graph_search.organizations(conditions)

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana University Bloomington')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [OpenStruct.new(object: 'Certification',
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
end
