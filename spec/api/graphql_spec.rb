describe API::GraphSearch do
  before(:all) do
    reset_neo4j
    import_into_neo4j('../../support/fixtures/json/ce_registry/credential/2_valid.json')
    import_into_neo4j('../../support/fixtures/json/ce_registry/credential/3_valid.json')
    import_into_neo4j('../../support/fixtures/json/ce_registry/organization/1_valid.json')
    import_into_neo4j('../../support/fixtures/json/ce_registry/organization/2_valid.json')
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
      expect_json_keys('data.credentials.0', %i[type name naics])
      expect_json('data.credentials.0',
                  type: 'Certification',
                  name: 'Health Informatics',
                  naics: %w[622 62231])
    end
  end
end
