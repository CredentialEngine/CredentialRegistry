ENV['RACK_ENV'] ||= 'development'

load File.expand_path('lib/tasks/environment.rake', __dir__)
require 'standalone_migrations'
require_relative 'config/dotenv_load'

StandaloneMigrations::Tasks.load_tasks
ActiveRecord::Base.schema_format = :sql
