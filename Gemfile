source 'https://rubygems.org'

# API
gem 'grape', '~> 0.19'
gem 'grape-entity', '~> 0.6'
gem 'grape-middleware-logger', '~> 1.8.0'
gem 'jsonpath', '~> 0.8'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 0.16', require: 'kaminari/grape'
gem 'api-pagination', '~> 4.5'
gem 'rack-contrib', '~> 1.4'
gem 'swagger-blocks', '~> 2.0.0'
gem 'rack-cors', '~> 0.4.1'

# Persistence
gem 'pg', '~> 0.20', platform: :mri
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3', platform: :jruby
gem 'standalone_migrations', '~> 4.0'

# Versioning
gem 'paper_trail', '~> 4.1'

# Validation
gem 'json-schema', '~> 2.8'

# Utilities
gem 'activesupport', '~> 4.2'
gem 'virtus', '~> 1.0'
gem 'ruby-progressbar', '~> 1.7', '>= 1.7.5'
gem 'chronic', '~> 0.10.2'

# Markdown parser
gem 'kramdown', '~> 1.13', '>= 1.11.1'

# Search
gem 'pg_search', '~> 2.0'

# Configuration management
gem 'dotenv', '~> 2.2', groups: %i[development test]

# debugging
gem 'pry', '~> 0.10.4', groups: %i[development test], platforms: :mri
gem 'byebug', groups: %i[development test], platform: :mri

# Development tools
group :development do
  # Code quality tools
  gem 'overcommit', '~> 0.39'
  gem 'rubocop', '~> 0.48', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.2', require: false, group: %i[development test]

group :test do
  gem 'factory_girl', '~> 4.8'
  gem 'database_cleaner', '~> 1.5'
  gem 'coveralls', require: false, platform: :mri
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 3.0'
  gem 'test_after_commit', '~> 1.1'
  gem 'faker', '~> 1.8'
end
