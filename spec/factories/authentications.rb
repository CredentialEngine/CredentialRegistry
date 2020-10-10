FactoryBot.define do
  factory :authentication do
    provider { :google }
    publisher
    uid { Faker::Lorem.characters(number: 16) }
  end
end
