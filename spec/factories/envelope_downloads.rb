FactoryBot.define do
  factory :envelope_download do
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    envelope_community { create(:envelope_community, :with_random_name) }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy

    trait :failed do
      finished_at { Time.current }
      internal_error_message { Faker::Lorem.sentence }
      started_at { Time.current }
      status { :finished }
    end

    trait :finished do
      finished_at { Time.current }
      started_at { Time.current }
      status { :finished }
    end

    trait :in_progress do
      started_at { Time.current }
      status { :in_progress }
    end
  end
end
