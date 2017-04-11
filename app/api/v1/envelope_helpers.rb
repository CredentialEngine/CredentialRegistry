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
                               { '@id' => params[:id] }.to_json)

    envelopes = envelopes.in_community(select_community)

    if envelopes.blank?
      err = ['No matching resource found']
      json_error! err, nil, :not_found
    end

    @envelope = envelopes.first
  end

  def select_community
    given_community || default_community
  end

  def default_community
    @default ||= EnvelopeCommunity.host_mapped(@env['HTTP_HOST']) ||
                 EnvelopeCommunity.default.name
  end

  def community_error(msg)
    json_error! [msg], nil, :unprocessable_entity
  end

  def normalized_community_names
    [
      params[:community_name].try(:underscore),
      params[:envelope_community].try(:underscore)
    ]
  end

  def given_community
    url_name, env_name = normalized_community_names
    matching_url_env_community(url_name, env_name) ||
      valid_env_community(env_name)
  end

  # Check if the community in the envelope and URL are identical
  def matching_url_env_community(url_name, env_name)
    if env_name && url_name && env_name != url_name
      community_error(':envelope_community in URL and envelope don\'t match.')
    end

    url_name
  end

  # Check if the community in the envelope is the same as the default
  def valid_env_community(env_name)
    if env_name && env_name != default_community
      community_error(
        ':envelope_community in envelope does not match the default ' \
        "community (#{default_community})."
      )
    end
  end
end
