module API
  module Entities
    # Presenter for an Envelope Version
    class Version < Grape::Entity
      expose :head,
             documentation: { type: 'boolean',
                              desc: 'Tells if it\'s the current version' }
      expose :event,
             documentation: { type: 'string',
                              desc: 'What change caused the new version' }
      expose :created_at,
             documentation: { type: 'string',
                              desc: 'When the version was created' }
      expose :whodunnit,
             as: :actor,
             documentation: { type: 'string',
                              desc: 'Who performed the changes' }
      expose :url,
             documentation: { type: 'string', desc: 'Version URL' }
    end
  end
end
