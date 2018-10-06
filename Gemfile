source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 4.5'
gem 'grape', '~> 1.1'
gem 'grape-entity', '~> 0.7.1'
gem 'grape-middleware-logger', '~> 1.10'
gem 'hashie', '~> 3.6'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 0.8'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 0.16', require: 'kaminari/grape'
gem 'pundit', '~> 1.1'
gem 'rack-contrib', '~> 1.4'
gem 'rack-cors', '~> 0.4.1'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord-jdbcpostgresql-adapter', '~> 50', platform: :jruby
gem 'pg', '~> 0.20', platform: :mri
gem 'redis', '~> 4.0', '>= 4.0.1'
gem 'standalone_migrations', '~> 5.2'

# Versioning
gem 'paper_trail', '~> 4.1'

# Validation
gem 'json-schema', '~> 2.8'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.2', '>= 2.2.2'
gem 'dry-inflector'
gem 'dry-monads'
gem 'dry-struct'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.0', '>= 2.0.2'
gem 'ruby-progressbar', '~> 1.7', '>= 1.7.5'
gem 'virtus', '~> 1.0'

# Markdown parser
gem 'kramdown', '~> 1.13', '>= 1.11.1'

# Search
gem 'pg_search', '~> 2.0'

# Configuration management
gem 'dotenv', '~> 2.2', groups: %i[development test]

# Debugging
gem 'byebug', groups: %i[development test], platform: :mri
gem 'pry', '~> 0.10.4', groups: %i[development test], platforms: :mri

# Development tools
group :development do
  # Code quality tools
  gem 'overcommit'
  gem 'rubocop', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.2', require: false, group: %i[development test]

group :test do
  gem 'coveralls', require: false, platform: :mri
  gem 'database_cleaner', '~> 1.5'
  gem 'factory_bot', '~> 4.8'
  gem 'faker', '~> 1.8'
  gem 'rspec'
  gem 'test_after_commit', '~> 1.1'
  gem 'vcr'
  gem 'webmock'
end
