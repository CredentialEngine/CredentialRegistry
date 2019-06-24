require 'active_support/concern'
require 'notify_gremlin_indexer'

# When included schedule for indexing by Gremlin.
module GremlinIndexable
  extend ActiveSupport::Concern

  included do
    after_commit :notify_indexer_update, on: %i[create update]

    def notify_indexer_update
      if deleted_at_changed? && deleted_at.present?
        NotifyGremlinIndexer.delete_one(id)
      else
        NotifyGremlinIndexer.index_one(id)
      end
    end
  end
end
