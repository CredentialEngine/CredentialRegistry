FactoryBot.define do
  factory :json_schema do
    name { Faker::Lorem.word }
    schema { Faker::Json.shallow_json }
  end
end
