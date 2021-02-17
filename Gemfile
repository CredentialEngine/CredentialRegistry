source 'https://rubygems.org'

# API
gem 'api-pagination', '~> 4.5'
gem 'aws-sdk-s3', '~> 1.53'
gem 'grape', '~> 1.1'
gem 'grape-entity', '~> 0.7.1'
gem 'grape-kaminari', '~> 0.2'
gem 'grape-middleware-logger', '~> 1.10'
gem 'hashie', '~> 3.6'
gem 'hashie-forbidden_attributes', '~> 0.1'
gem 'jsonpath', '~> 0.8'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 1.2'
gem 'linkeddata', '~> 3.0'
gem 'puma', '~> 5.0'
gem 'pundit', '~> 1.1'
gem 'rack-contrib', '~> 2.2'
gem 'rack-cors', '~> 1.0.5'
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'swagger-blocks', '~> 2.0.0'

# Persistence
gem 'activerecord', '~> 5.2'
gem 'activerecord-import', '~> 1.0'
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'pg', '= 0.20', platform: :mri
gem 'redis', '~> 4.0', '>= 4.0.1'
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
gem 'dry-struct', '~> 1.3'
gem 'encryptor', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'ruby-progressbar', '~> 1.10'
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
gem 'sidekiq', '~> 6.1'

# Debugging
gem 'byebug', '~> 11.1',  groups: %i[development test], platform: :mri
gem 'pry', '~> 0.13', groups: %i[development test], platform: :mri

# Monitoring
gem 'airbrake-ruby', '~> 4.14'
gem 'skylight', '~> 4.3'

# Development tools
group :development do
  gem 'grape-raketasks'
  # Code quality tools
  gem 'overcommit', '~> 0.57'
  gem 'rubocop', '~> 1.2', require: false
  gem 'rubocop-faker', '~> 1.1', require: false
  gem 'rubocop-performance', '~> 1.8'
  gem 'rubocop-rspec', '~> 2.0.0.pre', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.3', require: false, group: %i[development test]

group :test do
  gem 'coveralls', '~> 0.8', require: false, platform: :mri
  gem 'database_cleaner', '~> 1.8'
  gem 'factory_bot', '~> 6.1'
  gem 'faker', '~> 2.14'
  gem 'rspec', '~> 3.10'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.9'
end

group :development, :test do
  gem 'rb-readline', '~> 0.5'
end
