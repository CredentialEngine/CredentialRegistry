require 'search/repository'

describe Search::Repository do
  let(:repo) { Search::Repository.new }

  it { expect(repo.client.ping).to be true }
  it { expect(repo.index).to eq :metadataregistry_test }
end
