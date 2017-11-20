FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    publisher

    trait :admin_account do
      admin
      publisher nil
    end
  end
end
