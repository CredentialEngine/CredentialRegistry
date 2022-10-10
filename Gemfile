source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 5.0'
gem 'aws-sdk-s3', '~> 1.114'
gem 'grape', '~> 1.6'
gem 'grape-entity', '~> 0.10'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', '~> 1.12'
gem 'hashie', '~> 5.0'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 2.5'
gem 'kaminari', '~> 1.2'
gem 'linkeddata', '~> 3.2'
gem 'pundit', '~> 2.2'
gem 'rack-contrib', '~> 2.3'
gem 'rack-cors', '~> 1.1'
gem 'rake', '~> 13.0'
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord-import', '~> 1.4'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '~> 1.4', platform: :mri
gem 'redis', '~> 4.8'
gem 'with_advisory_lock', '~> 4.6'

# Versioning
gem 'paper_trail', '~> 13.0', require: false

# Validation
gem 'json-schema', '~> 3.0'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.2'
gem 'dry-inflector', '~> 0.3'
gem 'dry-monads', '~> 1.4'
gem 'dry-struct', '~> 1.4'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'ruby-progressbar', '~> 1.11'
gem 'virtus', '~> 2.0'
gem 'uuid', '~> 2.3'

# Markdown parser
gem 'kramdown', '~> 2.4'
gem 'kramdown-parser-gfm', '~> 1.1'

# Search
gem 'pg_search', '~> 2.3'

# Configuration management
gem 'dotenv', '~> 2.8', groups: %i[development test]

# Background processing
gem 'activejob', '~> 7.0', require: 'active_job'
gem 'sidekiq', '~> 6.5'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake', '~> 13.0'
gem 'skylight', '~> 5.3'

# For console
gem 'pry', '~> 0.14'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.59'
  gem 'rubocop', '~> 1.36', require: false
  gem 'rubocop-faker', '~> 1.1', require: false
  gem 'rubocop-performance', '~> 1.15'
  gem 'rubocop-rspec', '~> 2.13', require: false
end

group :test do
  gem 'coveralls_reborn', '~> 0.25', require: false
  gem 'database_cleaner', '~> 2.0'
  gem 'factory_bot', '~> 6.2'
  gem 'faker', '~> 2.23'
  gem 'rspec', '~> 3.11'
  gem 'vcr', '~> 6.1'
  gem 'webmock', '~> 3.18'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', '~> 0.3', require: false
  gem 'byebug', '~> 11.1', platform: :mri
  gem 'puma', '~> 5.6'
  gem 'rb-readline', '~> 0.5'
end
