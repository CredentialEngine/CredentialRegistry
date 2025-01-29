FactoryBot.define do
  factory :envelope_download do
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    envelope_community { create(:envelope_community, :with_random_name) }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end
end
