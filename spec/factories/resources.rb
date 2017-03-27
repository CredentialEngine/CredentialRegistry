FactoryGirl.define do
  factory :resource, class: 'Hashie::Mash' do
    name 'The Constitution at Work'
    url 'http://example.org/activities/16/detail'
    description 'In this activity students will analyze envelopes ...'
    registry_metadata { attributes_for(:registry_metadata) }
  end

  factory :cer_org, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:CredentialOrganization' }
    add_attribute(:'@context') do
      {
        schema: 'http://schema.org/',
        dc: 'http://purl.org/dc/elements/1.1/',
        dct: 'http://dublincore.org/dc/terms/',
        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        ceterms: 'http://purl.org/ceterms/terms/'
      }
    end
    add_attribute(:'@id') { Envelope.generate_ctid }
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Org' }
  end

  factory :cer_cred, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ceterms:Credential' }
    add_attribute(:'@context') do
      {
        schema: 'http://schema.org/',
        dc: 'http://purl.org/dc/elements/1.1/',
        dct: 'http://dublincore.org/dc/terms/',
        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        ceterms: 'http://purl.org/ceterms/terms/'
      }
    end
    add_attribute(:'@id') { Envelope.generate_ctid }
    add_attribute(:'ceterms:ctid') { send(:'@id') }
    add_attribute(:'ceterms:name') { 'Test Cred' }
    add_attribute(:'ceterms:url') { { '@id': 'http://example.com/test-cred' } }
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
