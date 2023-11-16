source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 5.0'
gem 'aws-sdk-s3', '~> 1.134'
gem 'bundler', '~> 2.4.10'
gem 'grape', '~> 1.8'
gem 'grape-entity', '~> 1.0'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', '~> 1.12'
gem 'hashie', '~> 5.0'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 2.7'
gem 'kaminari', '~> 1.2'
gem 'pundit', '~> 2.3'
gem 'rack-contrib', '~> 2.3'
gem 'rack-cors', '~> 2.0'
gem 'rake', '~> 13.0'
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord-import', '~> 1.5'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '~> 1.5', platform: :mri
gem 'redis', '~> 4.8'
gem 'with_advisory_lock', '~> 4.6'

# Versioning
gem 'paper_trail', '~> 15.0', require: false

# Validation
gem 'json-schema', '~> 4.1'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.4'
gem 'dry-inflector', '~> 1.0'
gem 'dry-monads', '~> 1.6'
gem 'dry-struct', '~> 1.6'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'ruby-progressbar', '~> 1.13'
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
gem 'activejob', '= 7.0.8', require: 'active_job'
gem 'sidekiq', '~> 7.1'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake', '~> 13.0'
gem 'newrelic_rpm', '~> 9.6'

# For console
gem 'pry', '~> 0.14'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.60'
  gem 'rubocop', '~> 1.56', require: false
  gem 'rubocop-faker', '~> 1.1', require: false
  gem 'rubocop-performance', '~> 1.19'
  gem 'rubocop-rspec', '~> 2.24', require: false
end

group :test do
  gem 'coveralls_reborn', '~> 0.28', require: false
  gem 'database_cleaner', '~> 2.0'
  gem 'factory_bot', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'rspec', '~> 3.12'
  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.19'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', '~> 0.3', require: false
  gem 'byebug', '~> 11.1', platform: :mri
  gem 'puma', '~> 6.3'
  gem 'rb-readline', '~> 0.5'
end
