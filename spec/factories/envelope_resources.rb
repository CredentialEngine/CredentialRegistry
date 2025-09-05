FactoryBot.define do
  factory :envelope_resource do
    envelope factory: %i[envelope]
    processed_resource { envelope.processed_resource }
    envelope_id { envelope.id }
    envelope_type { envelope.envelope_type }
    resource_id do
      processed_resource[envelope.envelope_community.id_field] ||
        processed_resource.try(:[], '@id') ||
        envelope.id
    end
    updated_at { envelope.updated_at }
  end
end
