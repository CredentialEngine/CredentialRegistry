require_relative '../../app/services/notify_gremlin_indexer'

describe NotifyGremlinIndexer, type: :service do
  let(:redis) { double('redis') }

  before(:each) do
    redis_pool = double('redis_pool')
    allow(redis_pool).to receive(:with).and_yield(redis)
    allow(MR).to receive(:redis_pool).and_return(redis_pool)
  end

  describe '.index_one' do
    it 'sends the index one message' do
      command = { command: 'index_one', id: 1 }
      expect(redis).to receive(:lpush).with('gremlin-cer:waiting', command.to_json)
      NotifyGremlinIndexer.index_one(1)
    end

    it 'sends the delete one message' do
      command = { command: 'delete_one', id: 1 }
      expect(redis).to receive(:lpush).with('gremlin-cer:waiting', command.to_json)
      NotifyGremlinIndexer.delete_one(1)
    end

    it 'sends the index all message' do
      command = { command: 'index_all', id: nil }
      expect(redis).to receive(:lpush).with('gremlin-cer:waiting', command.to_json)
      NotifyGremlinIndexer.index_all
    end

    it 'sends the create indices message' do
      command = { command: 'create_indices', id: nil }
      expect(redis).to receive(:lpush).with('gremlin-cer:waiting', command.to_json)
      NotifyGremlinIndexer.create_indices
    end
  end
end
