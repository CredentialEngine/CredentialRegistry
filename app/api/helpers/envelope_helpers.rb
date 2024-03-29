# Envelopes specific helpers
module EnvelopeHelpers
  extend Grape::API::Helpers

  # verbs used on the info docs for the "send" and "delete" actions
  def info_verbs
    if params[:envelope_id]
      %i[PATCH DELETE] # for single_envelope we use patch and delete
    else
      %i[POST PUT] # for envelopes we use post and put
    end
  end

  # schemas for this community
  def community_schemas
    JsonSchema.pluck(:name).select do |schema|
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
          *community_schemas.map { |name| url :schemas, name },
          url(:schemas, :paradata)
        ]
      },
      delete => { accepted_schemas: [url(:schemas, :delete_envelope)] }
    }
  end

  def scoped_envelopes
    Envelope.select_scope(params[:include_deleted])
  end

  def find_envelopes
    scoped_envelopes.in_community(community)
  end

  def find_envelope
    @envelope = scoped_envelopes.community_resource(
      select_community,
      params[:id]&.downcase
    )

    return unless @envelope.blank?

    err = ['No matching resource found']
    json_error! err, nil, :not_found
  end
end
