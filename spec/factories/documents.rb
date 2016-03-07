FactoryGirl.define do
  factory :document do
    doc_type :resource_data
    doc_version '0.52.0'
    user_envelope { JWT.encode(attributes_for(:resource), nil, 'none') }
    user_envelope_format :json

    trait :with_id do
      doc_id 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56'
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :with_node_headers do
      node_headers_format :jwt
      node_headers { JWT.encode({ header: 'value' }, nil, 'none') }
    end

    trait :with_xml_envelope do
      user_envelope_format :xml
      user_envelope do
        JWT.encode({ value: attributes_for(:resource).to_xml(root: 'rdf') },
                   nil, 'none')
      end
    end
  end
end
