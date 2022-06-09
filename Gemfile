source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 5.0'
gem 'aws-sdk-s3', '~> 1.110'
gem 'grape', '~> 1.6'
gem 'grape-entity', '~> 0.10'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', '~> 1.12'
gem 'hashie', '~> 5.0'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 2.3'
# gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 1.2'
gem 'linkeddata', '~> 3.2'
gem 'puma', '~> 5.6'
gem 'pundit', '~> 2.1'
gem 'rack-contrib', '~> 2.3'
gem 'rack-cors', '~> 1.1'
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord-import', '~> 1.3'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '~> 1.2', platform: :mri
gem 'redis', '~> 4.5'
gem 'with_advisory_lock', '~> 4.6'

# Versioning
gem 'paper_trail', '~> 12.1'

# Validation
gem 'json-schema', '~> 2.8'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.2'
gem 'dry-inflector', '~> 0.2'
gem 'dry-monads', '~> 1.4'
gem 'dry-struct', '~> 1.4'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'ruby-progressbar', '~> 1.11'
gem 'virtus', '~> 1.0'
gem 'uuid', '~> 2.3'

# Markdown parser
gem 'kramdown', '~> 2.3'
gem 'kramdown-parser-gfm', '~> 1.1'

# Search
gem 'pg_search', '~> 2.3'

# Configuration management
gem 'dotenv', '~> 2.7', groups: %i[development test]

# Background processing
gem 'activejob', '~> 6.1', require: 'active_job'
gem 'sidekiq', '~> 6.4'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake', '~> 12.0'
gem 'skylight', '~> 5.1'

# For console
gem 'pry'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.58'
  gem 'rubocop', '~> 1.24', require: false
  gem 'rubocop-faker', '~> 1.1', require: false
  gem 'rubocop-performance', '~> 1.13'
  gem 'rubocop-rspec', '~> 2.7', require: false
end

group :test do
  gem 'coveralls', '~> 0.8', require: false, platform: :mri
  gem 'database_cleaner', '~> 2.0'
  gem 'factory_bot', '~> 6.2'
  gem 'faker', '~> 2.19'
  gem 'rspec', '~> 3.10'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.14'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', '~> 0.3', require: false
  gem 'byebug', '~> 11.1', platform: :mri
  gem 'rb-readline', '~> 0.5'
end
