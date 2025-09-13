module API
  module Entities
    # Presenter for an Envelope Version
    class EnvelopeEvent < Grape::Entity
      expose :envelope_ceterms_ctid,
             documentation: { type: 'string',
                              desc: 'The CTID of the envelope' }
      expose :event,
             documentation: { type: 'string',
                              desc: 'What change occurred' }
      expose :created_at,
             documentation: { type: 'datetime',
                              desc: 'When the event was created' }
    end
  end
end
