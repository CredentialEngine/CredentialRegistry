FactoryBot.define do
  factory :authentication do
    provider { :google }
    publisher
    uid { Faker::Lorem.characters(16) }
  end
end
