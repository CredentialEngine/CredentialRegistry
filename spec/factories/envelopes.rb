FactoryGirl.define do
  factory :envelope do
    envelope_type :resource_data
    envelope_version '0.52.0'
    resource { JWT.encode(attributes_for(:resource), nil, 'none') }
    resource_format :json
    resource_encoding :jwt

    trait :with_id do
      envelope_id 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56'
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :with_node_headers do
      node_headers_format :node_headers_jwt
      node_headers { JWT.encode({ header: 'value' }, nil, 'none') }
    end

    trait :with_xml_resource do
      resource_format :xml
      resource do
        JWT.encode({ value: attributes_for(:resource).to_xml(root: 'rdf') },
                   nil, 'none')
      end
    end
  end
end
