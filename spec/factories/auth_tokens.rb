FactoryBot.define do
  factory :auth_token do
    value { Faker::Lorem.characters(number: 32) }
    user

    trait :admin do
      # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
      user { create(:user, :admin_account) }
      # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    end

    trait :publisher do # rubocop:todo Lint/EmptyBlock
    end
  end
end
