ENV['RACK_ENV'] ||= 'development'

load File.expand_path('lib/tasks/environment.rake', __dir__)

if ENV['RACK_ENV'] == 'development'
  require 'grape-raketasks'
  require 'grape-raketasks/tasks'
end

require 'standalone_migrations'
require_relative 'config/dotenv_load'

StandaloneMigrations::Tasks.load_tasks
ActiveRecord::Base.schema_format = :sql
