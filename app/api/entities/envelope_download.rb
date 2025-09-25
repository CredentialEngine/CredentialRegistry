module API
  module Entities
    # Presenter for EnvelopeDownload
    class EnvelopeDownload < Grape::Entity
      expose :display_status, as: :status,
                              documentation: { type: 'string', desc: 'Status of download' }

      expose :url,
             documentation: { type: 'string', desc: 'AWS S3 URL' },
             if: ->(object) { object.finished? }

      expose :enqueued_at,
             documentation: { type: 'string', desc: 'When the download was enqueued' },
             if: ->(object) { object.pending? }

      expose :finished_at,
             documentation: { type: 'string', desc: 'When the download finished' },
             if: ->(object) { object.finished? }

      expose :started_at,
             documentation: { type: 'string', desc: 'When the download started' },
             if: ->(object) { object.in_progress? }
    end
  end
end
