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

      if ENV['LOKI_URL'].present?
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
        @loki_logger = nil
      end
    end

    def log_with_labels(level, message, labels_arg=nil)
      # Ensure labels start as a Hash, even if not provided
      labels = labels_arg.is_a?(Hash) ? labels_arg : {}

      # Add log level into the labels for improved querying in Loki/Grafana
      labels = labels.merge(level: level.to_s)

      # Compose a single log entry for traditional loggers
      composed = "#{message} #{labels.to_json}"

      # Build list of logger destinations: file/STDOUT and Loki (if enabled)
      loggers = [logger]
      loggers += [loki_logger] if loki_logger

      loggers.compact.each do |l|
        # Send log to each logger (either standard or Loki)
        if l.respond_to?(:add)
          begin
            if l.is_a?(LokiLogger)
              # Send message and labels via LokiLogger’s API (includes structured labels)
              l.public_send(level, message, labels: labels)
            else
              # Send message and attached labels as a string to standard logger
              l.public_send(level, composed)
            end
          rescue => e
            # Ensure we don’t break on a logger error; print to STDERR for notice
            STDERR.puts "[Logger Error]: #{e.class} #{e.message}"
          end
        end
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