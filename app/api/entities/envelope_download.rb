module API
  module Entities
    # Presenter for EnvelopeDownload
    class EnvelopeDownload < Grape::Entity
      expose :display_status, as: :status,
                              documentation: { type: 'string', desc: 'Status of download' }

      expose :url,
             documentation: { type: 'string', desc: 'AWS S3 URL' },
             if: ->(object) { object.finished? }
    end
  end
end
