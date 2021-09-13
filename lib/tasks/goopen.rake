namespace :goopen do
  desc 'Migrate LRv1 data for goopen'
  task migrate: :cer_environment do
    require 'goopen_migration'
    GoOpenMigration.migrate
  end
end
