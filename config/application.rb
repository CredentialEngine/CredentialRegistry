$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(File.dirname(__FILE__), '..', 'app')
%w[models validators api services].each do |load_path|
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app', load_path))
end

require 'boot'
Bundler.require :default, ENV['RACK_ENV']
if %w[development test].include?(ENV['RACK_ENV'])
  Dotenv.load '.env.local', ".env.#{ENV['RACK_ENV']}", '.env'
end

# Main application module
module MetadataRegistry
  VERSION = '0.6'.freeze

  def self.env
    ENV['RACK_ENV']
  end

  def self.connect
    config = StandaloneMigrations::Configurator.new.config_for(env)
    ActiveRecord::Base.establish_connection(config)
  end

  def self.connect_redis
    @redis_pool = ConnectionPool.new(size: 5) do
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

ActiveRecord::Base.raise_in_transactional_callbacks = true
ActiveRecord::Base.schema_format = :sql

Time.zone = 'UTC'
Chronic.time_class = Time.zone

MetadataRegistry.connect
MetadataRegistry.connect_redis

require 'paper_trail/frameworks/active_record'
require 'base'

# Neo4J setup
require 'neo4j'
require 'neo4j/core/cypher_session/adaptors/http'

neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(ENV['NEO4J_URL'])
Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }

begin
  Neo4j::Session.open(:server_db, ENV['NEO4J_URL'])
rescue Faraday::ConnectionFailed
  MR.logger.warn("Couldn't connect to Neo4J. GraphQL related features will not work.")
end
