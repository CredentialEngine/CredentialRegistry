require 'api/entities/version'

RSpec.describe API::Entities::Version do
  it 'uses author as the actor when representing decoded node headers' do
    version = Hashie::Mash.new(
      head: true,
      event: 'update',
      created_at: Time.zone.now.iso8601,
      author: 'api-actor',
      url: '/example'
    )

    payload = described_class.represent(version).as_json

    expect(payload).to include(actor: 'api-actor')
  end
end
