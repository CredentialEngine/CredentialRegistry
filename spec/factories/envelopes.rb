FactoryGirl.define do
  factory :envelope do
    envelope_type :resource_data
    envelope_version '0.52.0'
    resource { jwt_encode(attributes_for(:resource)) }
    resource_format :json
    resource_encoding :jwt
    resource_public_key { File.read('spec/support/fixtures/public_key.txt') }

    after(:build) do |envelope|
      envelope.envelope_community = EnvelopeCommunity.create_with(
        backup_item: 'learning-registry-test', default: true
      ).find_or_create_by!(name: 'learning_registry')
    end

    trait :with_id do
      envelope_id 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56'
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :with_node_headers do
      node_headers_format :node_headers_jwt
      node_headers { jwt_encode({ header: 'value' }, signed: false) }
    end

    trait :with_xml_resource do
      resource_format :xml
      resource do
        jwt_encode(value: attributes_for(:resource).to_xml(root: 'rdf'))
      end
    end

    trait :with_malformed_key do
      resource_public_key '----- MALFORMED PUBLIC KEY -----'
    end

    trait :with_different_key do
      resource_public_key { OpenSSL::PKey::RSA.generate(2048).public_key.to_s }
    end

    trait :with_invalid_resource do
      resource { jwt_encode(test: true) }
    end

    trait :from_different_user do
      private_key = OpenSSL::PKey::RSA.generate(2048)
      resource { jwt_encode(attributes_for(:resource), key: private_key) }
      resource_public_key { private_key.public_key.to_s }
    end

    trait :from_administrative_account do
      private_key = File.read('spec/support/fixtures/adm_private_key.txt')
      resource { jwt_encode(attributes_for(:resource), key: private_key) }
      resource_public_key do
        File.read('spec/support/fixtures/adm_public_key.txt')
      end
    end

    trait :from_cer do
      resource { jwt_encode(attributes_for(:cer_org)) }
      after(:build) do |envelope|
        envelope.envelope_community = EnvelopeCommunity.create_with(
          backup_item: 'ce-registry-test'
        ).find_or_create_by!(name: 'ce_registry')
      end
    end

    trait :with_cer_credential do
      resource { jwt_encode(attributes_for(:cer_cred)) }
    end

    trait :paradata do
      envelope_type 'paradata'
      resource { jwt_encode(attributes_for(:paradata)) }
    end
  end
end
