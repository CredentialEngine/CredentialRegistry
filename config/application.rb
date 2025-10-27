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
      # Load database configuration from a fixed, absolute path and perform
      # minimal, safe ENV interpolation without executing arbitrary ERB.
      config_path = MR.root_path.join('config', 'database.yml')
      raw = File.read(config_path.to_s)
      expanded = interpolate_env_only(raw)
      ActiveRecord::Base.configurations = YAML.safe_load(expanded, aliases: true)
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
      @loki_logger ||= if ENV['LOKI_URL'].present?
                         LokiLogger.new(
                           loki_url: ENV['LOKI_URL'],
                           default_labels: {
                             app: 'metadata_registry',
                             env: MR.env
                           },
                           username: ENV.fetch('LOKI_USERNAME', nil),
                           password: ENV.fetch('LOKI_PASSWORD', nil)
                         )
                       end
    end

    # The method is intentionally a single cohesive unit that delegates
    # logging to multiple back-ends; splitting it would add more
    # indirection without improving readability.
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def log_with_labels(level, message, labels_arg = nil)
      labels = labels_arg.is_a?(Hash) ? labels_arg : {}
      labels = labels.merge(level: level.to_s)
      composed = "#{message} #{labels.to_json}"
      loggers = [logger]
      loggers += [loki_logger] if loki_logger

      loggers.compact.each do |l|
        next unless l.respond_to?(:add)

        begin
          if l.is_a?(LokiLogger)
            l.public_send(level, message, labels: labels)
          else
            l.public_send(level, composed)
          end
        rescue StandardError => e
          warn "[Logger Error]: #{e.class} #{e.message}"
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    attr_reader :redis_pool

    # Replace "<%= ENV['VAR'] %>" and "<%= ENV[\"VAR\"] %>" with the corresponding
    # environment variable values and strip any other ERB tags to avoid executing
    # arbitrary code in configuration files.
    def interpolate_env_only(str)
      s = str.gsub(/<%=\s*ENV\[['"]([^'"]+)['"]\]\s*%>/) { ENV.fetch(Regexp.last_match(1), '') }
      # Remove any remaining ERB tags (e.g., control flow) defensively
      s.gsub(/<%[^%]*%>/m, '')
    end

    def root_path
      @root_path ||= Pathname.new(File.expand_path('..', __dir__))
    end

    def envelope_publication_statuses
      { full: 0, provisional: 1 }
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
