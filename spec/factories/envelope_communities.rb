FactoryBot.define do
  factory :envelope_community do
    name { 'learning_registry' }
    default { false }
    backup_item { 'learning-registry-test' }

    trait :with_random_name do
      name { Faker::Lorem.word }
      backup_item { "#{name}-test" }
    end
  end
end
