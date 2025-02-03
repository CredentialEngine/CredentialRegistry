# EnvelopeCommunity specific helpers
module CommunityHelpers
  extend Grape::API::Helpers

  def select_community
    given_community || default_community
  end

  def default_community
    @default_community ||= EnvelopeCommunity.host_mapped(@env['HTTP_HOST']) ||
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
    return unless env_name && env_name != default_community

    community_error(
      ':envelope_community in envelope does not match the default ' \
      "community (#{default_community})."
    )
  end
end
