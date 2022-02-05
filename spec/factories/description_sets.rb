FactoryBot.define do
  factory :description_set do
    ceterms_ctid { Envelope.generate_ctid }
    path { Faker::Lorem.word }
    uris { [Faker::Internet.url] }
    envelope_community { nil }
    envelope_resource { nil }

    after(:build) do |envelope|
      envelope.envelope_community ||= EnvelopeCommunity.create_with(
        backup_item: 'learning-registry-test', default: !EnvelopeCommunity.default
      ).find_or_create_by!(name: 'learning_registry')
    end
  end
end
