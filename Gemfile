source 'https://rubygems.org'

# API
gem 'grape', '~> 0.19'
gem 'grape-entity', '~> 0.6'
gem 'jwt', '~> 1.5'
gem 'kaminari', '~> 0.16', require: 'kaminari/grape'
gem 'api-pagination', '~> 4.3'
gem 'rack-contrib', '~> 1.4'
gem 'swagger-blocks', '~> 2.0.0'
gem 'rack-cors', '~> 0.4.0'

# Persistence
gem 'pg', '~> 0.18', platform: :mri
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3', platform: :jruby
gem 'standalone_migrations', '~> 4.0'

# Versioning
gem 'paper_trail', '~> 4.1'

# Validation
gem 'json-schema', '~> 2.6'

# Utilities
gem 'activesupport', '~> 4.2'
gem 'virtus', '~> 1.0'
gem 'ruby-progressbar', '~> 1.7', '>= 1.7.5'
gem 'chronic', '~> 0.10.2'

# Markdown parser
gem 'kramdown', '~> 1.11', '>= 1.11.1'

# Search
gem 'pg_search', '~> 1.0', '>= 1.0.6'

# Configuration management
gem 'dotenv', '~> 2.1', groups: [:development, :test]

# debugging
gem 'pry', '~> 0.10.4', groups: [:development, :test], platforms: :mri
gem 'byebug', groups: [:development, :test]

# Development tools
group :development do
  # Code quality tools
  gem 'overcommit', '~> 0.32'
  gem 'rubocop', '~> 0.37', require: false
end

# RSpec driven API testing
gem 'airborne', '~> 0.2', require: false, group: [:development, :test]

group :test do
  gem 'factory_girl', '~> 4.5'
  gem 'database_cleaner', '~> 1.5'
  gem 'coveralls', require: false, platform: :mri
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 2.0'
  gem 'test_after_commit', '~> 1.1'
end
