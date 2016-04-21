module API
  module Entities
    # Presenter for an Envelope Version
    class Version < Grape::Entity
      expose :id,
             documentation: { type: 'integer',
                              desc: 'Global unique identifier' }
      expose :event,
             documentation: { type: 'event',
                              desc: 'What change caused the new version' }
      expose :whodunnit,
             as: :actor,
             documentation: { type: 'string',
                              desc: 'Who performed the changes' }
      expose :url,
             documentation: { type: 'string', desc: 'Version URL' },
             unless: ->(v, _opts) { v.event == 'create' } do |version|
        "/api/envelopes/#{version.reify.envelope_id}/versions/#{version.id}"
      end
    end
  end
end
