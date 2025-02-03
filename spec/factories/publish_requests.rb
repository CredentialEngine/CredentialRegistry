FactoryBot.define do
  factory :publish_request do
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    transient { envelope_community { create(:envelope_community) } }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    transient { organization { create(:organization) } }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    transient { publishing_organization { create(:organization) } }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    transient { user { create(:user) } } # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    transient { secondary_token { create(:auth_token) } }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    request_params do
      {
        raw_resource: attributes_for(:resource).to_json,
        envelope_community: envelope_community.name,
        organization_id: organization.id,
        publishing_organization_id: publishing_organization&.id,
        user_id: user.id,
        secondary_token: secondary_token&.value,
        skip_validation: true
      }.to_json
    end
  end
end
