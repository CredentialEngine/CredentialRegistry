source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 6.0'
gem 'aws-sdk-s3', '~> 1.184'
gem 'base64', '~> 0.3'
gem 'bundler', '= 2.7.2'
gem 'fiddle', '~> 1.1'
gem 'grape', '= 2.2.0'
gem 'grape-entity', '~> 1.0'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', '~> 2.4.0'
gem 'hashie', '~> 5.0'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 2.10'
gem 'kaminari', '~> 1.2'
gem 'ostruct', '~> 0.6'
gem 'parallel', '~> 1.27'
gem 'puma', '~> 6.6'
gem 'pundit', '~> 2.5'
gem 'rack-contrib', '~> 2.5'
gem 'rack-cors', '~> 2.0'
gem 'rake', '~> 13.2'
gem 'rdoc', '~> 6.15.0'
gem 'rubyzip', '~> 2.4', require: 'zip'
gem 'swagger-blocks', '~> 3.0.0'

# Persistence
gem 'activerecord-import', '~> 2.1'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '~> 1.5', platform: :mri
gem 'redis', '~> 4.8'
gem 'with_advisory_lock', '~> 5.1'

# Versioning
gem 'paper_trail', '~> 16.0', require: false

# Validation
gem 'json-schema', '~> 5.1'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.5'
gem 'dry-inflector', '~> 1.2'
gem 'dry-monads', '~> 1.8'
gem 'dry-struct', '~> 1.8'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'ruby-progressbar', '~> 1.13'
gem 'virtus', '~> 2.0'
gem 'uuid', '~> 2.3'

# Markdown parser
gem 'kramdown', '~> 2.5'
gem 'kramdown-parser-gfm', '~> 1.1'

# Search
gem 'pg_search', '~> 2.3'

# Configuration management
gem 'dotenv', '~> 3.1', groups: %i[development test]

# Background processing
gem 'activejob', '= 8.0.2', require: 'active_job'
gem 'sidekiq', '= 7.3.8'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake', '~> 13.0'
gem 'newrelic_rpm', '~> 9.18'

# For console
gem 'irb', '~> 1.15'
gem 'pry', '~> 0.15'
gem 'reline', '~> 0.6'

# For lokilogger
gem 'http'

# Vulnerability fixes
gem 'rack', '~> 2.2.20'
gem 'rexml', '>= 3.4.4'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.67'
  gem 'rubocop', '~> 1.75', require: false
  gem 'rubocop-factory_bot', '~> 2.27', require: false
  gem 'rubocop-faker', '~> 1.3', require: false
  gem 'rubocop-performance', '~> 1.25'
  gem 'rubocop-rake', '~> 0.7', require: false
  gem 'rubocop-rspec', '~> 3.6', require: false
end

group :test do
  gem 'coveralls', require: false
  gem 'database_rewinder', '~> 1.1'
  gem 'factory_bot', '~> 6.5'
  gem 'faker', '~> 3.5'
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '>= 0.21.2'
  gem 'simplecov_json_formatter'
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.25'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', '~> 0.3', require: false
  gem 'byebug', '~> 12.0', platform: :mri
  gem 'rb-readline', '~> 0.5'
end
