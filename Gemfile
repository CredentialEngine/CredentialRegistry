source 'https://rubygems.org'

# API
gem 'grape', '~> 0.14'
gem 'grape-entity', '~> 0.5'
gem 'grape-swagger', '~> 0.20'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 0.16', require: 'kaminari/grape'
gem 'api-pagination', '~> 4.3'
gem 'rack-contrib', '~> 1.4'

# Persistence
gem 'pg', '~> 0.18', platform: :mri
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3', platform: :jruby
gem 'standalone_migrations', '~> 4.0'

# Versioning
gem 'paper_trail', '~> 4.1'

# Validation
gem 'json-schema', '~> 2.6'

# Utilities
gem 'activesupport', '~> 4.2'
gem 'virtus', '~> 1.0'

# Configuration management
gem 'dotenv', '~> 2.1', groups: [:development, :test]

# Development tools
group :development do
  # Code quality tools
  gem 'overcommit', '~> 0.32'
  gem 'rubocop', '~> 0.37', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.2', require: false, group: [:development, :test]

group :test do
  gem 'factory_girl', '~> 4.5'
  gem 'database_cleaner', '~> 1.5'
  gem 'coveralls', require: false
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 2.0'
end
