FactoryBot.define do
  factory :publish_request do
    transient { envelope_community { create(:envelope_community) } }
    transient { organization { create(:organization) } }
    transient { publishing_organization { create(:organization) } }
    transient { user { create(:user) } }
    transient { secondary_token { create(:auth_token) } }
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
