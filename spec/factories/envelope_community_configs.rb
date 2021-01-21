FactoryBot.define do
  factory :envelope_community_config do
    description { Faker::Lorem.sentence }
    envelope_community
    payload { JSON(Faker::Json.shallow_json) }
  end
end
