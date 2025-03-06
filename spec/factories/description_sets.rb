FactoryBot.define do
  factory :description_set do
    ceterms_ctid { Envelope.generate_ctid }
    path { Faker::Lorem.word }
    uris { [Faker::Internet.url] }
    envelope_community { nil }
    envelope_resource { nil }
  end
end
