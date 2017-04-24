ENV['RACK_ENV'] ||= 'development'

require 'standalone_migrations'

if %w[development test].include?(ENV['RACK_ENV'])
  require 'dotenv'
  Dotenv.load '.env.local', ".env.#{ENV['RACK_ENV']}", '.env'
end

StandaloneMigrations::Tasks.load_tasks
ActiveRecord::Base.schema_format = :sql
