FactoryGirl.define do
  factory :publisher do
    admin
    contact_info { Faker::Lorem.paragraph }
    description { Faker::Lorem.sentence }
    name { Faker::Company.name }
  end
end
