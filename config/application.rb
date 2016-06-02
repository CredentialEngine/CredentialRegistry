$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
%w(models validators api services).each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV['RACK_ENV']
Dotenv.load '.env.local', ".env.#{ENV['RACK_ENV']}", '.env'

# Main application module
module LearningRegistry
  def self.env
    ENV['RACK_ENV']
  end

  def self.connect
    config = StandaloneMigrations::Configurator.new.config_for(env)
    ActiveRecord::Base.establish_connection(config)
  end

  def self.dumps_path
    'tmp/dumps'
  end
end

ActiveRecord::Base.raise_in_transactional_callbacks = true

LearningRegistry.connect

require 'paper_trail/frameworks/active_record'
require 'base'
