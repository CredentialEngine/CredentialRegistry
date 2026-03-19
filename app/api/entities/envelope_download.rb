module API
  module Entities
    # Presenter for EnvelopeDownload
    class EnvelopeDownload < Grape::Entity
      expose :display_status, as: :status,
                              documentation: { type: 'string', desc: 'Status of download' }

      expose :last_published_at,
             documentation: { type: 'string', desc: 'Timestamp of the latest publish event included in this download' }

      expose :enqueued_at,
             documentation: { type: 'string', desc: 'When the download was enqueued' },
             if: ->(object) { object.pending? }

      expose :finished_at,
             documentation: { type: 'string', desc: 'When the download finished' },
             if: ->(object) { object.finished? }

      expose :started_at,
             documentation: { type: 'string', desc: 'When the download started' },
             if: ->(object) { object.in_progress? }

      expose :url,
             documentation: { type: 'string', desc: 'AWS S3 URL' },
             if: ->(object) { object.finished? }

      expose :zip_files,
             documentation: { type: 'array', is_array: true, desc: 'ZIP files produced by the workflow' },
             if: ->(object) { object.finished? }
    end
  end
end
