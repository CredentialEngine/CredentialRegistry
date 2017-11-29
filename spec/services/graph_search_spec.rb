require_relative '../../app/services/graph_search'
require_relative '../../app/models/query_condition'

describe GraphSearch, type: :service do
  let(:graph_search) { GraphSearch.new }

  before(:all) do
    reset_neo4j
    %w[credential/3 credential/4 assessment_profile/2 assessment_profile/3
       learning_opportunity_profile/2 learning_opportunity_profile/3].each do |file|
      import_into_neo4j("../../support/fixtures/json/ce_registry/#{file}_import.json")
    end
  end

  describe '#organizations' do
    it 'returns organizations according to the conditions related to credentials' do
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

    it 'returns organizations according to the conditions related to assessments' do
      conditions = [QueryCondition.new(object: 'AssessmentProfile',
                                       element: 'estimatedCost/audienceType/targetNodeName',
                                       value: 'Citizen'),
                    QueryCondition.new(element: 'agentSectorType/targetNodeName', value: 'Public')]

      organizations = graph_search.organizations(conditions)

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana State Board of Nursing')
    end

    it 'returns organizations according to the conditions related to learning opportunities' do
      conditions = [QueryCondition.new(object: 'LearningOpportunityProfile',
                                       element: 'estimatedCost/price',
                                       value: 1640),
                    QueryCondition.new(element: 'foundingDate', value: '1971')]

      organizations = graph_search.organizations(conditions)

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana Commission for Higher Education')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'AssessmentProfile',
                                       element: 'estimatedCost/price',
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

    it 'filters credentials according to the roles' do
      roles = %w[OFFERED REVOKED]

      credentials = graph_search.credentials([], roles)

      expect(credentials.size).to eq(1)
      expect(credentials.last.props[:name]).to eq('Health Informatics')
    end
  end

  describe '#assessments' do
    it 'returns assessments according to the some conditions' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'targetContactPoint/name',
                                       value: 'Organization Contact Information'),
                    QueryCondition.new(element: 'hasGroupEvaluation', value: false)]

      assessments = graph_search.assessment_profiles(conditions, ['OWNED'])

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:type]).to eq('AssessmentProfile')
      expect(assessments.last.props[:name]).to eq('Pharmacy Technician Program')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'description',
                                       value: 'WRONG VALUE')]

      assessments = graph_search.assessment_profiles(conditions)

      expect(assessments).to be_empty
    end

    it 'filters assessments according to the roles' do
      roles = %w[REGULATED]

      assessments = graph_search.assessment_profiles([], roles)

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:name]).to eq('Certified Registered Nurse Anesthetist (CRNA)')
    end
  end

  describe '#learning_opportunities' do
    it 'returns learning opportunities according to the some conditions' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'subjectWebpage',
                                       value: 'http://www.iue.edu'),
                    QueryCondition.new(element: 'jurisdiction/globalJurisdiction', value: true)]

      assessments = graph_search.learning_opportunity_profiles(conditions, ['REGULATED'])

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:type]).to eq('LearningOpportunityProfile')
      expect(assessments.last.props[:name]).to eq('Certified Welder Courses')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'subjectWebpage',
                                       value: 'WRONG VALUE')]

      assessments = graph_search.learning_opportunity_profiles(conditions)

      expect(assessments).to be_empty
    end

    it 'filters learning opportunities according to the roles' do
      roles = %w[ACCREDITED]
      name = 'Certified Radiographic Interpreter (CRI) Seminars'

      assessments = graph_search.learning_opportunity_profiles([], roles)

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:name]).to eq(name)
    end
  end
end
