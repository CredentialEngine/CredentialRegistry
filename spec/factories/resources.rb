FactoryGirl.define do
  factory :resource, class: 'Hashie::Mash' do
    name 'The Constitution at Work'
    url 'http://example.org/activities/16/detail'
    description 'In this activity students will analyze envelopes ...'
    registry_metadata { attributes_for(:registry_metadata) }
  end

  factory :cer_org, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:CredentialOrganization' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Org' }
    add_attribute(:'ceterms:description') { 'Org Description' }
    add_attribute(:'ceterms:subjectWebpage') { 'http://example.com/test-org' }
    add_attribute(:'ceterms:agentType') do
      [{
        '@type' => 'ceterms:CredentialAlignmentObject',
        'ceterms:framework' => 'OrganizationType',
        'ceterms:targetNode' => 'orgType:ProfessionalAssociation',
        'ceterms:targetNodeName' => 'Professional Association'
      }]
    end
    add_attribute(:'ceterms:agentSectorType') do
      [{
        '@type' => 'ceterms:CredentialAlignmentObject',
        'ceterms:framework' => 'AgentSector',
        'ceterms:targetNode' => 'agentSector:PrivateNonProfit',
        'ceterms:targetNodeName' => 'Private Not-For-Profit'
      }]
    end
  end

  factory :cer_cred, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:Certificate' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Cred' }
    add_attribute(:'ceterms:description') { 'Test Cred Description' }
    add_attribute(:'ceterms:subjectWebpage') { 'http://example.com/test-cred' }
    add_attribute(:'ceterms:credentialStatusType') do
      {
        '@type' => 'ceterms:CredentialAlignmentObject',
        'ceterms:framework' => 'CredentialStatus',
        'ceterms:targetNode' => 'credentialStat:Active',
        'ceterms:targetNodeName' => 'Active'
      }
    end
  end

  factory :cer_ass_prof, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:AssessmentProfile' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Assessment Profile' }
  end

  factory :cer_cond_man, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:ConditionManifest' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Cond Man' }
    add_attribute(:'ceterms:conditionManifestOf') { [{ '@id' => 'AgentID' }] }
  end

  factory :cer_cost_man, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:CostManifest' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Cost Man' }
    add_attribute(:'ceterms:costDetails') { 'CostDetails' }
    add_attribute(:'ceterms:costManifestOf') { [{ '@id' => 'AgentID' }] }
  end

  factory :cer_lrn_opp_prof, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:CostManifest' }
    add_attribute(:'@context') { 'http://credreg.net/ctdl/schema/context/json' }
    add_attribute(:'@id') do
      "http://credentialengineregistry.org/resources/#{Envelope.generate_ctid}"
    end
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Lrn Opp Prof' }
    add_attribute(:'ceterms:costDetails') { 'CostDetails' }
    add_attribute(:'ceterms:costManifestOf') { [{ '@id' => 'AgentID' }] }
  end

  factory :paradata, class: 'Hashie::Mash' do
    add_attribute(:'@context') { 'http://www.w3.org/ns/activitystreams' }
    name 'High school English teachers taught this 15 times on May 2011'
    type 'Taught'
    actor do
      {
        type: 'Group',
        id: 'teacher',
        keywords: ['high school', 'english']
      }
    end
    object 'http://URL/to/lesson'
    measure do
      { measureType: 'count', value: 15 }
    end
    date '2011-05-01/2011-05-31'
  end
end
