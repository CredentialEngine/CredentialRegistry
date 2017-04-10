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
          *community_schemas.map { |name| url :api, :schemas, name },
          url(:api, :schemas, :paradata)
        ]
      },
      delete => { accepted_schemas: [url(:api, :schemas, :delete_envelope)] }
    }
  end

  def find_envelopes
    Envelope.select_scope(params[:include_deleted]).in_community(community)
  end

  def find_envelope
    envelopes = Envelope.where('processed_resource @> ?',
                               { '@id' => combine_id_format }.to_json)

    unless params[:envelope_community].blank?
      # TODO: else default community (#36)
      envelopes = envelopes.in_community(community)
    end

    if envelopes.blank?
      err = ['No matching resource found']
      json_error! err, nil, :not_found
    end

    @envelope = envelopes.first
  end

  def combine_id_format
    if params[:id] && params[:format] && params[:id] =~ /:/
      # resource IDs like
      # http://credentialengine.org/resource/urn:ctid:123e4567-e89b-...
      # if sent URL encoded
      # http%3A%2F%2Fcredentialengine.org%2Fresource%2Furn%3Actid%3A123...
      # => params[:id] everything before the .
      # => params[:format] everything after the .
      "#{params[:id]}.#{params[:format]}"
    else
      params[:id]
    end
  end
end
