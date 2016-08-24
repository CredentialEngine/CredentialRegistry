FactoryGirl.define do
  factory :delete_envelope, parent: :delete_token do
    envelope_id { create(:envelope).envelope_id }
  end
end
