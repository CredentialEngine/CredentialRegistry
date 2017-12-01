FactoryBot.define do
  factory :organization do
    admin
    description { Faker::Lorem.sentence }
    name { Faker::Company.name }
  end
end
