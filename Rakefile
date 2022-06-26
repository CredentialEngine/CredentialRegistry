ENV['RACK_ENV'] ||= 'development'

require_relative 'config/application'
require_relative 'config/ar_tasks'

Rake.add_rakelib 'lib/tasks'

if ENV['RACK_ENV'] == 'development'
  require 'grape-raketasks'
  require 'grape-raketasks/tasks'
end
