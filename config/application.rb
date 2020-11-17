$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services jobs].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV['RACK_ENV']

require 'dotenv_load'
require 'airbrake'

if ENV['RACK_ENV'] == 'production'
  require 'skylight'
  Skylight.start!(file: 'config/skylight.yml')
end

# Main application module
module MetadataRegistry
  VERSION = '0.6'.freeze

  def self.cache
    @cache ||= ActiveSupport::Cache::RedisStore.new(
      "#{ENV['REDIS_URL']}/0/cache"
    )
  end

  def self.env
    ENV['RACK_ENV']
  end

  def self.connect
    config = StandaloneMigrations::Configurator.new.config_for(env)
    ActiveRecord::Base.establish_connection(config)
  end

  def self.connect_redis
    @redis_pool = ConnectionPool.new(size: ENV.fetch('REDIS_POOL_SIZE', 5)) do
      Redis.new(url: ENV['REDIS_URL'])
    end
  end

  def self.redis_pool
    @redis_pool
  end

  def self.logger
    @logger ||= begin
      logger = Logger.new("log/#{env}.log")

      log_level = ENV['LOG_LEVEL']
      logger.level = Logger.const_get(log_level) if log_level

      logger
    end
  end

  def self.root_path
    @root_path ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  def self.dump_path
    root_path.join('db', 'dump', 'content.sql')
  end

  def self.test_keys
    @test_keys ||= begin
      keys = %i[public private].each_with_object({}) do |k, hash|
        hash[k] = File.read(root_path.join('fixtures', 'keys', "#{k}_key.txt")).gsub(/\n$/, '')
      end
      OpenStruct.new(**keys)
    end
  end
end

MR = MetadataRegistry # Alias for application module

ActiveJob::Base.queue_adapter = :sidekiq

ActiveRecord::Base.schema_format = :sql

Time.zone = 'UTC'
Chronic.time_class = Time.zone

MetadataRegistry.connect
MetadataRegistry.connect_redis

require 'paper_trail/frameworks/active_record'
require 'base'
