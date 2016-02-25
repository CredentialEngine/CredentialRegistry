source 'https://rubygems.org'

# API
gem 'grape', '~> 0.14'
gem 'grape-entity', '~> 0.5'
gem 'grape-swagger', github: 'ruby-grape/grape-swagger', branch: 'swagger-2.0'
gem 'jwt', '~> 1.5'

# Persistence
gem 'pg', '~> 0.18'
gem 'standalone_migrations', '~> 4.0'

# Utilities
gem 'activesupport', '~> 4.2'

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
end
