$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services jobs].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

require 'dotenv_load'
require 'airbrake_load'
require 'arel_nodes_cte'
require 'attribute_normalizers'
require 'postgresql_adapter_reconnect'
require_relative '../lib/loki_logger'

# Main application module
module MetadataRegistry
  VERSION = '0.6'.freeze

  class << self
    def cache
      @cache ||= ActiveSupport::Cache::RedisCacheStore.new(
        url: "#{ENV.fetch('REDIS_URL', nil)}/0/cache"
      )
    end

    def connect
      config = ERB.new(File.read('config/database.yml')).result
      ActiveRecord::Base.configurations = YAML.safe_load(config, aliases: true)
      ActiveRecord::Base.establish_connection(env.to_sym)
    end

    def statement_timeout(timeout)
      ActiveRecord::Base.connection.execute("set statement_timeout to #{timeout}")
    rescue ActiveRecord::NoDatabaseError
      # Can't set the timeout when there's no DB
    end

    def connect_redis
      @redis_pool = ConnectionPool.new(size: ENV.fetch('REDIS_POOL_SIZE', 5)) do
        Redis.new(url: ENV.fetch('REDIS_URL', nil))
      end
    end

    def development?
      env == 'development'
    end

    def dump_path
      root_path.join('db', 'dump', 'content.sql')
    end

    def env
      ENV.fetch('RACK_ENV', nil)
    end

    def logger
      @logger ||= begin
        file_logger = Logger.new(MR.root_path.join('log', "#{MR.env}.log"))
        stdout_logger = Logger.new($stdout)
        loggers = [file_logger]
        loggers << stdout_logger if MR.env == 'production'
        if (log_level = ENV.fetch('LOG_LEVEL', nil)).present?
          loggers.each { |l| l.level = Logger.const_get(log_level) }
        end
        ActiveSupport::BroadcastLogger.new(*loggers)
      end
    end

    def loki_logger
      return @loki_logger if defined?(@loki_logger) && @loki_logger

      # Check if the 'LOKI_URL' environment variable is set and not empty.
      if ENV['LOKI_URL'].present?
        # Instantiate a new LokiLogger with configuration from environment variables.
        # - loki_url: URL endpoint for the Loki logging service.
        # - default_labels: Metadata tags for log entries (application and environment).
        # - username/password: Optional authentication credentials for Loki.
        @loki_logger = LokiLogger.new(
          loki_url: ENV['LOKI_URL'],
          default_labels: {
            app: 'metadata_registry',
            env: MR.env
          },
          username: ENV['LOKI_USERNAME'], 
          password: ENV['LOKI_PASSWORD']
        )
      else
        # If 'LOKI_URL' is not set, do not instantiate LokiLogger; set @loki_logger to nil.
        @loki_logger = nil
      end
    end

    def log_with_labels(level, message, labels_arg=nil)
      # Convert labels_arg to a Hash if provided and valid; else, use an empty Hash.
      labels = labels_arg.is_a?(Hash) ? labels_arg : {}
      # Compose the log message by appending labels as JSON.
      composed = "#{message} #{labels.to_json}"
      # Attempt to retrieve all broadcasted loggers; fallback to the main logger if not available.
      loggers = logger.instance_variable_get(:@broadcasts) rescue [logger]
      # Send the composed message to each logger at the specified log level.
      loggers.each { |l| l.send(level, composed) }

      
      begin
        # Proceed only if loki_logger is available.
        if loki_logger
          # Check if loki_logger responds to the given log level method.
          if loki_logger.respond_to?(level)
            begin
              # Determine the arity of the log level method.
              # If method takes 1 argument, call with message only.
              # If method takes more, call with message and labels.
              loki_logger.method(level).arity == 1 ?
                loki_logger.public_send(level, message) :
                loki_logger.public_send(level, message, labels: labels)
            rescue ArgumentError
              # If the method signature is unexpected, fallback to calling with message only.
              loki_logger.public_send(level, message)
            end
          end
        end
      rescue => e
        puts "Loki logging error: #{e.class}: #{e.message}"
        puts e.backtrace.take(5).join("\n")
      end
    end

    attr_reader :redis_pool

    def root_path
      @root_path ||= Pathname.new(File.expand_path('..', __dir__))
    end
  end
end

MR = MetadataRegistry # Alias for application module

ActiveJob::Base.queue_adapter = :sidekiq

ActiveRecord.schema_format = :sql

ActiveRecord::SchemaDumper.ignore_tables = %w[]

# rubocop:todo Layout/LineLength
ActiveSupport.to_time_preserves_timezone = :zone # Opt in to the future behavior in ActiveSupport 8.0
# rubocop:enable Layout/LineLength

Time.zone_default = Time.find_zone!('UTC')
Chronic.time_class = Time.zone

MetadataRegistry.connect
MetadataRegistry.statement_timeout(ENV.fetch('STATEMENT_TIMEOUT', '300000')) # 5 min
MetadataRegistry.connect_redis

require 'init_sidekiq'
require 'paper_trail'
require 'paper_trail/frameworks/active_record'
require 'base'