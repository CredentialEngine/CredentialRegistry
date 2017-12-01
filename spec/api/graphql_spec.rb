describe API::GraphSearch do
  before(:all) do
    reset_neo4j
    %w[credential/3 credential/4 assessment_profile/2 assessment_profile/3
       learning_opportunity_profile/2 learning_opportunity_profile/3].each do |file|
      import_into_neo4j("../../support/fixtures/json/ce_registry/#{file}_import.json")
    end
  end

  context 'POST organizations' do
    it 'retrieves the organizations' do
      payload = {
        query: 'query searchOrganizations($conditions: [QueryCondition], $roles: [AgentRole]) {'\
                 'organizations(conditions: $conditions, roles: $roles) {'\
                   'ctid type name'\
                 '}'\
               '}',
        variables: {
          conditions: [
            {
              object: 'Credential',
              element: 'renewal/name',
              value: 'Health Informatics'
            },
            {
              element: 'type',
              value: 'QACredentialOrganization'
            },
            {
              element: 'fein',
              value: '23-7455576'
            }
          ]
        }
      }

      post '/graph-search', payload

      expect_status(:ok)
      expect_json_sizes('data', organizations: 1)
      expect_json_keys('data.organizations.0', %i[ctid type name])
      expect_json('data.organizations.0',
                  ctid: 'ce-6A62B250-A1A2-4D31-A702-CDC2437EFD31',
                  type: 'QACredentialOrganization',
                  name: 'Indiana University Bloomington')
    end
  end

  context 'POST credentials' do
    it 'retrieves the credentials' do
      payload = {
        query: 'query searchCredentials($conditions: [QueryCondition], $roles: [AgentRole]) {'\
                 'credentials(conditions: $conditions, roles: $roles) {'\
                   'type name naics'\
                 '}'\
               '}',
        variables: {
          conditions: [
            {
              object: 'Organization',
              element: 'address/addressLocality',
              value: 'Big Rapids'
            },
            {
              element: 'type',
              value: 'Certification'
            }
          ]
        }
      }

      post '/graph-search', payload

      expect_status(:ok)
      expect_json_sizes('data', credentials: 1)
      expect_json_keys('data.credentials.0', %i[type name naics])
      expect_json('data.credentials.0',
                  type: 'Certification',
                  name: 'Health Informatics',
                  naics: %w[622 62231])
    end
  end

  context 'POST assessments' do
    it 'retrieves the assessments' do
      payload = {
        query: 'query searchAssessments($conditions: [QueryCondition], $roles: [AgentRole]) {'\
                 'assessments(conditions: $conditions, roles: $roles) {'\
                   'type name hasGroupParticipation'\
                 '}'\
               '}',
        variables: {
          conditions: [
            {
              object: 'Organization',
              element: 'subjectWebpage',
              value: 'http://www.in.gov/pla/3722.htm'
            },
            {
              element: 'inLanguage',
              value: 'English'
            }
          ],
          roles: %w[ACCREDITED REGULATED]
        }
      }

      post '/graph-search', payload

      expect_status(:ok)
      expect_json_sizes('data', assessments: 1)
      expect_json_keys('data.assessments.0', %i[type name hasGroupParticipation])
      expect_json('data.assessments.0',
                  type: 'AssessmentProfile',
                  name: 'Certified Registered Nurse Anesthetist (CRNA)',
                  hasGroupParticipation: false)
    end
  end

  context 'POST learning_opportunities' do
    it 'retrieves the learning opportunities' do
      payload = {
        query: 'query searchLearningOpportunities($conditions: [QueryCondition],'\
                                                 '$roles: [AgentRole]) {'\
                 'learningOpportunities(conditions: $conditions, roles: $roles) {'\
                   'type name dateEffective'\
                 '}'\
               '}',
        variables: {
          conditions: [
            {
              object: 'Organization',
              element: 'agentType/targetNodeName',
              value: 'Four-Year College'
            },
            {
              element: 'dateEffective',
              value: '2017-09-01'
            }
          ],
          roles: ['REGULATED']
        }
      }

      post '/graph-search', payload

      expect_status(:ok)
      expect_json_sizes('data', learningOpportunities: 1)
      expect_json_keys('data.learningOpportunities.0', %i[type name dateEffective])
      expect_json('data.learningOpportunities.0',
                  type: 'LearningOpportunityProfile',
                  name: 'Certified Welder Courses',
                  dateEffective: '2017-09-01')
    end
  end

  context 'POST competencies' do
    it 'retrieves the competencies' do
      payload = {
        query: 'query searchCompetencies($conditions: [QueryCondition]) {'\
                 'competencies(conditions: $conditions) {'\
                   'type codedNotation'\
                 '}'\
               '}',
        variables: {
          conditions: [
            {
              object: 'ConditionProfile',
              element: 'jurisdiction/mainJurisdiction/geoURI',
              value: 'http://geonames.org/6252001/'
            },
            {
              object: 'Credential',
              element: 'estimatedDuration/exactDuration',
              value: 'P2Y'
            }
          ]
        }
      }

      post '/graph-search', payload

      expect_status(:ok)
      expect_json_sizes('data', competencies: 1)
      expect_json_keys('data.competencies.0', %i[type codedNotation])
      expect_json('data.competencies.0',
                  type: 'Competency',
                  codedNotation: 'c2d70f14-416e-11e7-98df-41f94c7896aa')
    end
  end
end
