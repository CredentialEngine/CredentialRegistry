$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services jobs].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/rails'
require 'opentelemetry/instrumentation/active_job'
require 'opentelemetry/instrumentation/redis'

require 'dotenv_load'
require 'airbrake_load'
require 'arel_nodes_cte'
require 'attribute_normalizers'
require 'postgresql_adapter_reconnect'

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
        # Initialize OpenTelemetry first
        configure_opentelemetry unless @opentelemetry_configured

        file_logger = Logger.new(root_path.join('log', "#{env}.log"))
        stdout_logger = Logger.new($stdout)
        otel_logger = OpenTelemetry.logger

        loggers = [file_logger, otel_logger] # Now includes OTLP logger
        loggers << stdout_logger if env == 'production'

        if (log_level = ENV.fetch('LOG_LEVEL', nil)).present?
          loggers.each { _1.level = Logger.const_get(log_level) }
        end

        ActiveSupport::BroadcastLogger.new(*loggers)
      end
    end

    def configure_opentelemetry
      return if @opentelemetry_configured

      OpenTelemetry::SDK.configure do |c|
        c.service_name = 'metadata-registry'
        c.service_version = VERSION
        
        # Auto-instrumentation
        c.use 'OpenTelemetry::Instrumentation::Rails'
        c.use 'OpenTelemetry::Instrumentation::ActiveJob'
        c.use 'OpenTelemetry::Instrumentation::Redis'
        
        # OTLP Exporter configuration
        c.add_log_record_processor(
          OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
            OpenTelemetry::Exporter::OTLP::LogsExporter.new(
              endpoint: ENV.fetch('OTLP_ENDPOINT', 'http://localhost:4317'),
              headers: { "Authorization" => "Bearer #{ENV['OTLP_AUTH_TOKEN']}" }
            )
          )
        )
      end

      @opentelemetry_configured = true
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
MetadataRegistry.configure_opentelemetry

require 'init_sidekiq'
require 'paper_trail'
require 'paper_trail/frameworks/active_record'
require 'base'
