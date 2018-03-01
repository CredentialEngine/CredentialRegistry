FactoryBot.define do
  factory :organization do
    admin
    description { Faker::Lorem.sentence }
    name { Faker::Company.name }
    _ctid { SecureRandom.uuid }
  end
end
