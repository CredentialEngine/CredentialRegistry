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

      organizations = GraphSearch.new(conditions).organizations

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana University Bloomington')
    end

    it 'returns organizations according to the conditions related to assessments' do
      conditions = [QueryCondition.new(object: 'AssessmentProfile',
                                       element: 'estimatedCost/audienceType/targetNodeName',
                                       value: 'Citizen'),
                    QueryCondition.new(element: 'agentSectorType/targetNodeName', value: 'Public')]

      organizations = GraphSearch.new(conditions).organizations

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana State Board of Nursing')
    end

    it 'returns organizations according to the conditions related to learning opportunities' do
      conditions = [QueryCondition.new(object: 'LearningOpportunityProfile',
                                       element: 'estimatedCost/price',
                                       value: 1640),
                    QueryCondition.new(element: 'foundingDate', value: '1971')]

      organizations = GraphSearch.new(conditions).organizations

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:type]).to eq('QACredentialOrganization')
      expect(organizations.last.props[:name]).to eq('Indiana Commission for Higher Education')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'AssessmentProfile',
                                       element: 'estimatedCost/price',
                                       value: 'WRONG VALUE')]

      organizations = GraphSearch.new(conditions).organizations

      expect(organizations).to be_empty
    end

    it 'filters organizations according to the roles' do
      conditions = [QueryCondition.new(element: 'type', value: 'QACredentialOrganization')]
      roles = %w[OFFERED REVOKED]

      organizations = GraphSearch.new(conditions, roles).organizations

      expect(organizations.size).to eq(1)
      expect(organizations.last.props[:name]).to eq('Indiana University Bloomington')
    end
  end

  describe '#credentials' do
    it 'returns credentials according to the some conditions' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'address/addressLocality',
                                       value: 'Big Rapids'),
                    QueryCondition.new(object: 'ConditionProfile',
                                       element: 'targetAssessment/name',
                                       value: 'CSP Examination'),
                    QueryCondition.new(object: 'Competency',
                                       element: 'codedNotation',
                                       value: 'c2d70f14-416e-11e7-98df-41f94c7896aa')]

      credentials = GraphSearch.new(conditions).credentials

      expect(credentials.size).to eq(1)
      expect(credentials.last.props[:type]).to eq('Certification')
      expect(credentials.last.props[:name]).to eq('Health Informatics')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'address/addressLocality',
                                       value: 'WRONG VALUE')]

      credentials = GraphSearch.new(conditions).credentials

      expect(credentials).to be_empty
    end

    it 'filters credentials according to the roles' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'type',
                                       value: 'CredentialOrganization')]
      roles = %w[OFFERED OWNED REVOKED]

      credentials = GraphSearch.new(conditions, roles).credentials

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

      assessments = GraphSearch.new(conditions, ['OWNED']).assessment_profiles

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:type]).to eq('AssessmentProfile')
      expect(assessments.last.props[:name]).to eq('Pharmacy Technician Program')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'description',
                                       value: 'WRONG VALUE')]

      assessments = GraphSearch.new(conditions).assessment_profiles

      expect(assessments).to be_empty
    end

    it 'filters assessments according to the roles' do
      roles = %w[REGULATED]

      assessments = GraphSearch.new([], roles).assessment_profiles

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

      assessments = GraphSearch.new(conditions, ['REGULATED']).learning_opportunity_profiles

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:type]).to eq('LearningOpportunityProfile')
      expect(assessments.last.props[:name]).to eq('Certified Welder Courses')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'subjectWebpage',
                                       value: 'WRONG VALUE')]

      assessments = GraphSearch.new(conditions).learning_opportunity_profiles

      expect(assessments).to be_empty
    end

    it 'filters learning opportunities according to the roles' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'type',
                                       value: 'QACredentialOrganization')]
      roles = %w[ACCREDITED]
      name = 'Certified Radiographic Interpreter (CRI) Seminars'

      assessments = GraphSearch.new(conditions, roles).learning_opportunity_profiles

      expect(assessments.size).to eq(1)
      expect(assessments.last.props[:name]).to eq(name)
    end
  end

  describe '#competencies' do
    it 'returns competencies according to the some conditions' do
      conditions = [QueryCondition.new(object: 'ConditionProfile',
                                       element: 'jurisdiction/mainJurisdiction/geoURI',
                                       value: 'http://geonames.org/6252001/'),
                    QueryCondition.new(object: 'Credential',
                                       element: 'estimatedDuration/exactDuration',
                                       value: 'P2Y'),
                    QueryCondition.new(element: 'codedNotation',
                                       value: 'c2d70f14-416e-11e7-98df-41f94c7896aa')]

      competencies = GraphSearch.new(conditions).competencies

      expect(competencies.size).to eq(1)
      expect(competencies.last.props[:type]).to eq('Competency')
      expect(competencies.last.props[:codedNotation]).to eq('c2d70f14-416e-11e7-98df-41f94c7896aa')
    end

    it 'returns nothing when conditions do not match any record' do
      conditions = [QueryCondition.new(object: 'Organization',
                                       element: 'address/addressLocality',
                                       value: 'WRONG VALUE')]

      competencies = GraphSearch.new(conditions).competencies

      expect(competencies).to be_empty
    end
  end
end
