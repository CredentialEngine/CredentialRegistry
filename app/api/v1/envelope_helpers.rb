# Envelopes specific helpers
module EnvelopeHelpers
  extend Grape::API::Helpers

  # verbs used on the info docs for the "send" and "delete" actions
  def info_verbs
    if params[:envelope_id]
      [:PATCH, :DELETE] # for single_envelope we use patch and delete
    else
      [:POST, :PUT] # for envelopes we use post and put
    end
  end

  # schemas for this community
  def community_schemas
    JSONSchema.all_schemas.select do |schema|
      schema.include? params[:envelope_community]
    end
  end

  # returns info for the  envelope, with the accepted_schemas for the
  # corresponding verbs.
  # Used for both envelopes and single_envelope
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
