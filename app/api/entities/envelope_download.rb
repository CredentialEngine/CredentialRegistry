module API
  module Entities
    # Presenter for EnvelopeDownload
    class EnvelopeDownload < Grape::Entity
      expose :id,
             documentation: { type: 'string', desc: 'ID (in UUID format)' }

      expose :status,
             documentation: { type: 'string', desc: 'Status of download' }

      expose :url,
             documentation: { type: 'string', desc: 'AWS S3 URL' }
    end
  end
end
