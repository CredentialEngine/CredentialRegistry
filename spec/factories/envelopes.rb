FactoryBot.define do
  factory :envelope do
    envelope_ceterms_ctid { processed_resource[:'ceterms:ctid'] || Envelope.generate_ctid }
    envelope_ctdl_type { 'ceterms:CredentialOrganization' }
    envelope_type { :resource_data }
    envelope_version { '0.52.0' }
    processed_resource { raw_resource }
    resource_format { :json }
    resource_encoding { :jwt }
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

    trait :with_invalid_resource do
      processed_resource { { test: true } }
    end

    trait :from_different_user do
      OpenSSL::PKey::RSA.generate(2048)
      processed_resource { attributes_for(:resource, provisional:) }
    end

    trait :from_administrative_account do
      processed_resource { attributes_for(:resource, provisional:) }
    end

    trait :from_cer do
      processed_resource { attributes_for(:cer_org, provisional:) }
      after(:build) do |envelope|
        envelope.envelope_community = EnvelopeCommunity.create_with(
          backup_item: 'ce-registry-test'
        ).find_or_create_by!(name: 'ce_registry')
      end
    end

    trait :with_cer_credential do
      processed_resource { attributes_for(:cer_cred, provisional:) }
    end

    trait :paradata do
      envelope_type { 'paradata' }
      processed_resource { attributes_for(:paradata, provisional:) }
    end

    trait :with_graph_competency_framework do
      processed_resource { attributes_for(:cer_graph_competency_framework, provisional:) }
    end

    trait :with_graph_collection do
      processed_resource { attributes_for(:cer_graph_collection, provisional:) }
    end

    trait :provisional do
      provisional { true }
    end

    transient do
      provisional { false }
      raw_resource { attributes_for(:resource, provisional:) }
    end
  end
end
