ENV['RACK_ENV'] ||= 'development'

Rake.add_rakelib 'lib/tasks'

if ENV['RACK_ENV'] == 'development'
  require 'grape-raketasks'
  require 'grape-raketasks/tasks'
end

require_relative 'config/ar_migrations'
require_relative 'config/dotenv_load'

ActiveRecordMigrations.load_tasks
ActiveRecord::Base.schema_format = :sql
