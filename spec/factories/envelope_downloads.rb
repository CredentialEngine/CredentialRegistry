FactoryBot.define do
  factory :envelope_download do
    envelope_community { create(:envelope_community, :with_random_name) }
  end
end
