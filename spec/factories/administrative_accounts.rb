FactoryBot.define do
  factory :administrative_account do
    public_key { Secrets.public_key }
  end
end
