FactoryBot.define do
  factory :json_context do
    add_attribute(:context) { JSON(Faker::Json.shallow_json) }
    url { Faker::Internet.url }
  end
end
