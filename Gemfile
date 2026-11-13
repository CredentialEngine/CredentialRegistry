source 'https://rubygems.org'

# API
# Modernization: direct dependencies are intentionally unlocked, except for minimum
# supported framework/security versions. Generate and commit Gemfile.lock.
gem 'api-pagination', '>= 7.1.0'
gem 'aws-sdk-s3'
gem 'base64'
gem 'bundler', '>= 2.7.2'
gem 'fiddle'
gem 'grape', '>= 4.1.0'
gem 'grape-entity'
gem 'grape-kaminari'
gem 'grape_logging', '>= 3.0.1'
gem 'hashie'
gem 'hashie-forbidden_attributes'
gem 'jsonpath'
gem 'jwt'
gem 'kaminari'
gem 'ostruct'
gem 'parallel'
gem 'puma'
gem 'pundit'
gem 'rack-contrib'
gem 'rack-cors'
gem 'rake'
gem 'rdoc'
gem 'rubyzip', require: 'zip'
gem 'swagger-blocks'
gem 'typhoeus'

# Persistence
gem 'activerecord-import'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', platform: :mri
gem 'redis'
gem 'with_advisory_lock'

# Versioning
gem 'paper_trail', require: false

# Validation
gem 'json-schema'

# Utilities
gem 'attribute_normalizer'
gem 'chronic'
gem 'connection_pool'
gem 'dry-inflector'
gem 'dry-monads'
gem 'dry-struct'
gem 'encryptor'
gem 'rest-client'
gem 'ruby-progressbar'
gem 'virtus'
gem 'uuid'

# Markdown parser
gem 'kramdown'
gem 'kramdown-parser-gfm'

# Search
gem 'pg_search'

# Configuration management
gem 'dotenv', groups: %i[development test]

# Background processing
gem 'activejob', require: 'active_job'
gem 'sidekiq'
gem 'sidekiq-failures'

# Monitoring
gem 'airbrake'
gem 'newrelic_rpm'

# For console
gem 'irb'
gem 'pry'
gem 'reline'

# For lokilogger
gem 'http'

# Rack 3 and security floors (remaining dependencies resolve to newest compatible releases)
gem 'rack', '>= 3.2.8'
gem 'rack-session', '>= 2.1.2'
gem 'rackup'
gem 'rexml'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit'
  gem 'rubocop', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-faker', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'coveralls', require: false
  gem 'database_rewinder'
  gem 'factory_bot'
  gem 'faker'
  gem 'rspec'
  gem 'simplecov'
  gem 'simplecov_json_formatter'
  gem 'vcr'
  gem 'webmock'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', require: false
  gem 'byebug', platform: :mri
  gem 'rb-readline'
end
