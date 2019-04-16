FactoryBot.define do
  factory :envelope_community do
    name { 'learning_registry' }
    default { false }
    backup_item { 'learning-registry-test' }
  end
end
