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
             documentation: { type: 'datetime',
                              desc: 'When the version was created' }
      expose :whodunnit,
             as: :actor,
             documentation: { type: 'string',
                              desc: 'Who performed the changes' }
      expose :url,
             documentation: { type: 'string', desc: 'Version URL' }

      def created_at
        Time.zone.parse(object.created_at) if object.created_at?
      end
    end
  end
end
