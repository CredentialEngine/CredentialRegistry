require 'envelope_dumps/base'

module EnvelopeDumps
  class GraphBuilder < Base # rubocop:todo Style/Documentation
    def bucket_name
      ENV.fetch('ENVELOPE_GRAPHS_BUCKET')
    end

    def build_content(envelope)
      envelope.processed_resource
    end
  end
end
