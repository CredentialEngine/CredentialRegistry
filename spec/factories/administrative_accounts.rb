FactoryGirl.define do
  factory :administrative_account do
    public_key { File.read('spec/support/fixtures/adm_public_key.txt') }
  end
end
