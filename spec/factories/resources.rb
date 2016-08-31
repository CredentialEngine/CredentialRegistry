FactoryGirl.define do
  factory :resource, class: 'Hashie::Mash' do
    name 'The Constitution at Work'
    url 'http://example.org/activities/16/detail'
    description 'In this activity students will analyze envelopes ...'
    registry_metadata { attributes_for(:registry_metadata) }
  end

  factory :credential_registry_org, class: 'Hashie::Mash' do
    add_attribute(:'@type') { 'ctdl:Organization' }
    add_attribute(:'ctdl:ctid') { Envelope.generate_ctid }
    name 'Test Org'
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
