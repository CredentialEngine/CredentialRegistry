FactoryBot.define do
  factory :json_context do
    url { Faker::Internet.url }
  end
end
