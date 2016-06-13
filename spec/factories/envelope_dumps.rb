FactoryGirl.define do
  factory :envelope_dump do
    provider 'archive.org'
    item 'learning-registry-test'
    location 'https://s3.us.archive.org/learning-registry-test/resource.txt'
    dumped_at { Date.new(2016, 1, 1) }
  end
end
