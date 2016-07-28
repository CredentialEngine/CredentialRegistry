# Envelopes specific helpers
module EnvelopeHelpers
  extend Grape::API::Helpers

  def info_verbs
    if params[:envelope_id]
      [:PATCH, :DELETE]
    else
      [:POST, :PUT]
    end
  end

  def community_schemas
    JSONSchema.all_schemas.select do |schema|
      schema.include? params[:envelope_community]
    end
  end

  def envelopes_info
    send, delete = info_verbs
    {
      send => {
        accepted_schemas: [
          *community_schemas.map { |name| url :api, :schemas, name },
          url(:api, :schemas, :paradata)
        ]
      },
      delete => { accepted_schemas: [url(:api, :schemas, :delete_envelope)] }
    }
  end
end
