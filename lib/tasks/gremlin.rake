namespace :gremlin do
  desc 'Creates indices for the CER entities in the Gremlin database.'
  task create_indices: :cer_environment do
    require 'notify_gremlin_indexer'
    NotifyGremlinIndexer.create_indices
  end

  desc 'Reindexes the envelope database in Gremlin.'
  task index_all: :cer_environment do
    require 'notify_gremlin_indexer'
    NotifyGremlinIndexer.index_all
  end
end
