source 'https://rubygems.org'

ruby file: '.ruby-version'

# API
gem 'api-pagination', '~> 6.0'
gem 'aws-sdk-s3', '~> 1.178'
gem 'bundler', '= 2.5.16'
gem 'fiddle', '~> 1.1'
gem 'grape', '~> 2.2'
gem 'grape-entity', '~> 1.0'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', github: 'soverin/grape-middleware-logger'
gem 'hashie', '~> 5.0'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 2.10'
gem 'kaminari', '~> 1.2'
gem 'ostruct', '~> 0.6'
gem 'parallel', '~> 1.26'
gem 'puma', '~> 6.5'
gem 'pundit', '~> 2.4'
gem 'rack-contrib', '~> 2.5'
gem 'rack-cors', '~> 2.0'
gem 'rake', '~> 13.2'
gem 'rdoc', '~> 6.11'
gem 'rubyzip', '~> 2.4', require: 'zip'
gem 'swagger-blocks', '~> 3.0.0'

# Persistence
gem 'activerecord-import', '~> 2.0'
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
gem 'dry-monads', '~> 1.7'
gem 'dry-struct', '~> 1.7'
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
gem 'activejob', '= 8.0.1', require: 'active_job'
gem 'sidekiq', '~> 7.3'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake', '~> 13.0'
gem 'newrelic_rpm', '~> 9.16'

# For console
gem 'pry', '~> 0.15'

# opentelemetry (otlp)
gem "opentelemetry-sdk"
gem "opentelemetry-instrumentation-all"

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.64'
  gem 'rubocop', '~> 1.70', require: false
  gem 'rubocop-factory_bot', '~> 2.26', require: false
  gem 'rubocop-faker', '~> 1.2', require: false
  gem 'rubocop-performance', '~> 1.23'
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 3.3', require: false
end

group :test do
  gem 'coveralls_reborn', '~> 0.28', require: false
  gem 'database_rewinder', github: 'kucho/database_rewinder',
                           branch: 'fix/rails-7-2-connection-warning'
  gem 'factory_bot', '~> 6.5'
  gem 'faker', '~> 3.5'
  gem 'rspec', '~> 3.13'
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.24'
end

group :development, :test do
  # RSpec driven API testing
  gem 'airborne', '~> 0.3', require: false
  gem 'byebug', '~> 11.1', platform: :mri
  gem 'rb-readline', '~> 0.5'
end
