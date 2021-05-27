source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 4.8'
gem 'aws-sdk-s3', '~> 1.92'
gem 'grape', '~> 1.5'
gem 'grape-entity', '~> 0.9'
gem 'grape-kaminari', '~> 0.4'
gem 'grape-middleware-logger', '~> 1.12'
gem 'hashie', '~> 4.1'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 1.1'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 1.2'
gem 'linkeddata', '~> 3.1'
gem 'puma', '~> 5.3'
gem 'pundit', '~> 2.1'
gem 'rack-contrib', '~> 2.3'
gem 'rack-cors', '~> 1.1'
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord', '>= 5.2.4.5'
gem 'activerecord-import', '~> 1.0'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '~> 1.2', platform: :mri
gem 'redis', '~> 4.2', '>= 4.0.1'
gem 'redis-activesupport', '~> 5.2'
gem 'standalone_migrations', '~> 6.0'

# Versioning
gem 'paper_trail', '~> 9.0'

# Validation
gem 'json-schema', '~> 2.8'

# Utilities
gem 'attribute_normalizer', '~> 1.2'
gem 'chronic', '~> 0.10.2'
gem 'connection_pool', '~> 2.2'
gem 'dry-inflector', '~> 0.2'
gem 'dry-monads', '~> 1.3'
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
gem 'activejob', '~> 5.2', require: 'active_job'
gem 'sidekiq', '~> 6.2'
gem 'sidekiq-failures', '~> 1.0'

# Monitoring
gem 'airbrake-ruby', '~> 5.2'
gem 'skylight', '~> 5.0'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.57'
  gem 'rubocop', '~> 1.11', require: false
  gem 'rubocop-faker', '~> 1.1', require: false
  gem 'rubocop-performance', '~> 1.10'
  gem 'rubocop-rspec', '~> 2.2', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.3', require: false, group: %i[development test]

group :test do
  gem 'coveralls', '~> 0.8', require: false, platform: :mri
  gem 'database_cleaner', '~> 2.0'
  gem 'factory_bot', '~> 6.1'
  gem 'faker', '~> 2.17'
  gem 'rspec', '~> 3.10'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.12'
end

group :development, :test do
  gem 'byebug', '~> 11.1',  groups: %i[development test], platform: :mri
  gem 'pry', '~> 0.14', groups: %i[development test], platform: :mri
  gem 'rb-readline', '~> 0.5'
end
