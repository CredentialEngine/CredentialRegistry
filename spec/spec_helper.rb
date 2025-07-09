require 'simplecov'
require 'simplecov-json'
require 'coveralls'
require 'simplecov_json_formatter'

SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter

SimpleCov.start 'rails' do
  coverage_dir 'coverage'
end

ENV['RACK_ENV'] ||= 'test'

require 'active_support'
require 'active_support/testing/time_helpers'
require 'airborne'
require 'vcr'
require File.expand_path('support/helpers', __dir__)
require File.expand_path('../config/environment', __dir__)
require 'webmock/rspec'
require_relative 'support/custom_matchers'
require_relative 'support/secrets'

ActiveJob::Base.logger = nil
ActiveJob::Base.queue_adapter = :test

# Airborne configuration
Airborne.configure do |config|
  config.rack_app = API::Base
end

ENV['ENCRYPTED_PRIVATE_KEY_SECRET'] ||= Secrets::ENCRYPTED_PRIVATE_KEY_SECRET
ENV['NEPTUNE_ENDPOINT'] ||= "https://#{Faker::Internet.domain_name}:8182"

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/cassettes'
  config.configure_rspec_metadata!
  config.preserve_exact_body_bytes { true }
  config.ignore_localhost = false
  config.filter_sensitive_data('<INTERNET_ARCHIVE_ACCESS_KEY>') do
    ENV.fetch('INTERNET_ARCHIVE_ACCESS_KEY', nil)
  end
  config.filter_sensitive_data('<INTERNET_ARCHIVE_SECRET_KEY>') do
    ENV.fetch('INTERNET_ARCHIVE_SECRET_KEY', nil)
  end
  config.hook_into :webmock
end

# Disable versioning
PaperTrail.enabled = false

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.after do
    DatabaseRewinder.clean
    clear_enqueued_jobs
  end

  config.disable_monkey_patching!

  config.include Helpers

  config.filter_run_excluding :broken

  config.tty = true
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    DatabaseRewinder.clean_all
  end

  config.include ActiveSupport::Testing::TimeHelpers

  # factory_bot configuration
  config.include FactoryBot::Syntax::Methods
  FactoryBot::SyntaxRunner.include Helpers
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
