# Pushes a message to the Redis queue that activates the Gremlin indexer.
class NotifyGremlinIndexer
  LIST = 'gremlin-cer:waiting'.freeze
  CREATE_INDICES = 'create_indices'.freeze
  INDEX_ONE = 'index_one'.freeze
  INDEX_ALL = 'index_all'.freeze
  BUILD_RELATIONSHIPS = 'build_relationships'.freeze
  DELETE_ONE = 'delete_one'.freeze
  UPDATE_CONTEXTS = 'update_contexts'.freeze
  REMOVE_ORPHANS = 'remove_orphans'.freeze

  class << self
    def index_one(id)
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(INDEX_ONE, id))
      end
    end

    def index_all
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(INDEX_ALL))
      end
    end

    def build_relationships
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(BUILD_RELATIONSHIPS))
      end
    end

    def delete_one(id)
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(DELETE_ONE, id))
      end
    end

    def create_indices
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(CREATE_INDICES))
      end
    end

    def update_contexts
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(UPDATE_CONTEXTS))
      end
    end

    def remove_orphans
      MR.redis_pool.with do |redis|
        redis.lpush(LIST, build_message(REMOVE_ORPHANS))
      end
    end

    private

    def build_message(command, id = nil)
      { command: command, id: id }.to_json
    end
  end
end
