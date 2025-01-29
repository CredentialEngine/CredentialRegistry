require_relative '../support/shared_contexts/envelopes_with_url'

RSpec.describe BatchDeleteEnvelopes, type: :service do
  include_context 'envelopes with url'

  it 'marks both envelopes as deleted' do
    described_class.new(envelopes, build(:delete_token)).run!

    expect(envelopes.map(&:deleted_at).all?).to be(true)
  end
end
