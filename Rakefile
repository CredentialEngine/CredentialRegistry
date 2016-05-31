require 'dotenv'
require 'standalone_migrations'

Dotenv.load '.env.local', ".env.#{ENV['RACK_ENV']}", '.env'
StandaloneMigrations::Tasks.load_tasks
