$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services jobs].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

# Modern OpenTelemetry requires (v1.0+)
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry-instrumentation-rails'
require 'opentelemetry-instrumentation-active_job'
require 'opentelemetry-instrumentation-redis'
require 'opentelemetry-logs'

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
        # Initialize OpenTelemetry if not already done
        configure_opentelemetry unless @opentelemetry_configured

        # Create loggers
        loggers = [
          Logger.new(root_path.join('log', "#{env}.log")),  # File logger
          OpenTelemetry.logger                              # OTLP logger
        ]
        
        # Add stdout in production
        loggers << Logger.new($stdout) if env == 'production'

        # Set log level if specified
        if (log_level = ENV.fetch('LOG_LEVEL', nil)).present?
          loggers.each { |l| l.level = Logger.const_get(log_level.upcase) }
        end

        # Combine loggers
        ActiveSupport::BroadcastLogger.new(*loggers).tap do |bl|
          bl.level = Logger::INFO  # Default level
        end
      end
    end

    def configure_opentelemetry
      return if @opentelemetry_configured

      OpenTelemetry::SDK.configure do |c|
        c.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'metadata-registry')
        c.service_version = VERSION
        
        # Auto-instrumentation
        c.use 'OpenTelemetry::Instrumentation::Rails'
        c.use 'OpenTelemetry::Instrumentation::ActiveJob'
        c.use 'OpenTelemetry::Instrumentation::Redis'
        
        # Configure both traces and logs
        c.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            OpenTelemetry::Exporter::OTLP::Exporter.new(
              endpoint: ENV.fetch('OTLP_ENDPOINT', 'http://localhost:4318'),
              headers: {}
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

# Configure ActiveJob
ActiveJob::Base.queue_adapter = :sidekiq

# ActiveRecord settings
ActiveRecord.schema_format = :sql
ActiveRecord::SchemaDumper.ignore_tables = %w[]

# Timezone settings
ActiveSupport.to_time_preserves_timezone = :zone
Time.zone_default = Time.find_zone!('UTC')
Chronic.time_class = Time.zone

# Initialize application components
MetadataRegistry.connect
MetadataRegistry.statement_timeout(ENV.fetch('STATEMENT_TIMEOUT', '300000')) # 5 min
MetadataRegistry.connect_redis
MetadataRegistry.configure_opentelemetry  # Ensure OTEL is initialized early

# Load remaining dependencies
require 'init_sidekiq'
require 'paper_trail'
require 'paper_trail/frameworks/active_record'
require 'base'