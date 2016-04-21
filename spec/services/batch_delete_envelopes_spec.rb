require_relative '../support/shared_contexts/envelopes_with_url'

describe BatchDeleteEnvelopes, type: :service do
  include_context 'envelopes with url'

  it 'marks both envelopes as deleted' do
    BatchDeleteEnvelopes.new(envelopes, envelopes.first.resource_public_key)
                        .run!

    expect(envelopes.map(&:deleted_at).all?).to eq(true)
  end
end
