require 'envelope_dumps/base'

module EnvelopeDumps
  class EnvelopeBuilder < Base # rubocop:todo Style/Documentation
    def bucket
      ENV.fetch('ENVELOPE_DOWNLOADS_BUCKET')
    end

    def build_content(envelope)
      API::Entities::Envelope.represent(envelope)
    end
  end
end
