$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services jobs].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV['RACK_ENV']

require 'dotenv_load'
require 'airbrake_load'
require 'postgresql_adapter_reconnect'

# Main application module
module MetadataRegistry
  VERSION = '0.6'.freeze

  class << self
    def cache
      @cache ||= ActiveSupport::Cache::RedisCacheStore.new(
        url: "#{ENV['REDIS_URL']}/0/cache"
      )
    end

    def connect
      config = ERB.new(File.read('config/database.yml')).result
      ActiveRecord::Base.configurations = YAML.load(config, aliases: true)
      ActiveRecord::Base.establish_connection(env.to_sym)
    end

    def connect_redis
      @redis_pool = ConnectionPool.new(size: ENV.fetch('REDIS_POOL_SIZE', 5)) do
        Redis.new(url: ENV['REDIS_URL'])
      end
    end

    def development?
      env == 'development'
    end

    def dump_path
      root_path.join('db', 'dump', 'content.sql')
    end

    def env
      ENV['RACK_ENV']
    end

    def logger
      @logger ||= begin
        logger = Logger.new("log/#{env}.log")

        log_level = ENV['LOG_LEVEL']
        logger.level = Logger.const_get(log_level) if log_level

        logger
      end
    end

    def redis_pool
      @redis_pool
    end

    def root_path
      @root_path ||= Pathname.new(File.expand_path('..', __dir__))
    end

    def test_keys
      @test_keys ||= begin
        keys = %i[public private].each_with_object({}) do |k, hash|
          hash[k] = File.read(root_path.join('fixtures', 'keys', "#{k}_key.txt")).gsub(/\n$/, '')
        end
        OpenStruct.new(**keys)
      end
    end
  end
end

MR = MetadataRegistry # Alias for application module

ActiveJob::Base.queue_adapter = :sidekiq

ActiveRecord.schema_format = :sql

ActiveRecord::SchemaDumper.ignore_tables = %w[
  indexed_envelope_resource_references
  indexed_envelope_resources
]

Time.zone = 'UTC'
Chronic.time_class = Time.zone

MetadataRegistry.connect
MetadataRegistry.connect_redis

require 'init_sidekiq'
require 'paper_trail'
require 'paper_trail/frameworks/active_record'
require 'base'
