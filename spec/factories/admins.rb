FactoryBot.define do
  factory :admin do
    sequence(:name) { |n| "Test Admin #{n}" }
  end
end
