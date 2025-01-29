FactoryBot.define do
  factory :envelope_resource do
    envelope factory: %i[envelope]
    processed_resource { envelope.processed_resource }
    envelope_id { envelope.id }
    envelope_type { envelope.envelope_type }
    resource_id { processed_resource.try(:[], '@id') || envelope.id }
    updated_at { envelope.updated_at }
  end
end
