FactoryBot.define do
  factory :envelope do
    envelope_ceterms_ctid { Envelope.generate_ctid }
    envelope_ctdl_type { 'ceterms:CredentialOrganization' }
    envelope_type { :resource_data }
    envelope_version { '0.52.0' }
    resource { jwt_encode(attributes_for(:resource, provisional:)) }
    resource_format { :json }
    resource_encoding { :jwt }
    resource_public_key { Secrets.public_key }
    resource_publish_type { 'primary' }

    after(:build) do |envelope|
      envelope.envelope_community ||= EnvelopeCommunity.create_with(
        backup_item: 'learning-registry-test', default: !EnvelopeCommunity.default
      ).find_or_create_by!(name: 'learning_registry')
    end

    after(:create) do |envelope|
      next if envelope.deleted?

      if (graph = envelope.processed_resource.try(:[], '@graph'))
        graph.each do |graph_obj|
          next if graph_obj['@id'].start_with?('_:')

          create(:envelope_resource, envelope: envelope, processed_resource: graph_obj)
        end
      else
        create(
          :envelope_resource,
          envelope: envelope,
          processed_resource: envelope.processed_resource
        )
      end
    end

    trait :with_id do
      envelope_id { 'ac0c5f52-68b8-4438-bf34-6a63b1b95b56' }
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :with_node_headers do
      node_headers_format { :node_headers_jwt }
      node_headers { jwt_encode({ header: 'value' }, signed: false) }
    end

    trait :with_xml_resource do
      resource_format { :xml }
      resource do
        jwt_encode({ value: <<~XML })
          <?xml version="1.0" encoding="UTF-8"?>
          <rdf xmlns:adms="http://www.w3.org/ns/adms#">
            <name>The Constitution at Work</name>
            <url>http://example.org/activities/16/detail</url>
            <description>In this activity students will analyze envelopes ...</description>
            <registry-metadata>
              <digital-signature>
                <key-location type="array">
                  <key-location>http://example.org/pubkey</key-location>
                </key-location>
              </digital-signature>
              <terms-of-service>
                <submission-tos>http://example.org/tos</submission-tos>
              </terms-of-service>
              <identity>
                <submitter>john doe &lt;john@example.org&gt;</submitter>
                <signer>Alpha Node &lt;administrator@example.org&gt;</signer>
                <submitter-type>user</submitter-type>
              </identity>
              <payload-placement>inline</payload-placement>
            </registry-metadata>
          </rdf>
        XML
      end
    end

    trait :with_malformed_key do
      resource_public_key { '----- MALFORMED PUBLIC KEY -----' }
    end

    trait :with_different_key do
      resource_public_key { OpenSSL::PKey::RSA.generate(2048).public_key.to_s }
    end

    trait :with_invalid_resource do
      resource { jwt_encode({ test: true }) }
    end

    trait :from_different_user do
      private_key = OpenSSL::PKey::RSA.generate(2048)
      resource { jwt_encode(attributes_for(:resource, provisional:), key: private_key) }
      resource_public_key { private_key.public_key.to_s }
    end

    trait :from_administrative_account do
      resource { jwt_encode(attributes_for(:resource, provisional:), key: Secrets.private_key) }
      resource_public_key { Secrets.public_key }
    end

    trait :from_cer do
      resource { jwt_encode(attributes_for(:cer_org, provisional:)) }
      after(:build) do |envelope|
        envelope.envelope_community = EnvelopeCommunity.create_with(
          backup_item: 'ce-registry-test'
        ).find_or_create_by!(name: 'ce_registry')
      end
    end

    trait :with_cer_credential do
      resource { jwt_encode(attributes_for(:cer_cred, provisional:)) }
    end

    trait :paradata do
      envelope_type { 'paradata' }
      resource { jwt_encode(attributes_for(:paradata, provisional:)) }
    end

    trait :with_graph_competency_framework do
      resource { jwt_encode(attributes_for(:cer_graph_competency_framework, provisional:)) }
    end

    trait :provisional do
      provisional { true }
    end

    transient do
      provisional { false }
    end
  end
end
