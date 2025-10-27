require_relative 'application_policy'

# Specifies policies for publish request API
class PublishRequestPolicy < ApplicationPolicy
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/AbcSize
  def show? # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
    return true if user.superadmin?

    request_user_id = parsed_params['user_id']
    return true if request_user_id && user.user&.id.to_s == request_user_id.to_s

    # Allow if it belongs to the same community (either via envelope or params)
    env_comm_id = record.envelope&.envelope_community_id || parsed_params['envelope_community_id']
    env_comm_id && user.community&.id.to_s == env_comm_id.to_s
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  Scope = Struct.new(:user, :scope) do
    def resolve
      return scope if user&.superadmin?

      # Limit to records that are clearly associated with the caller's community via envelope.
      if user&.community&.id
        scope.left_outer_joins(:envelope)
             .where('publish_requests.envelope_id IS NULL OR envelopes.envelope_community_id = ?', user.community.id)
      else
        scope.none
      end
    end
  end

  private

  def parsed_params
    @parsed_params ||= begin
      JSON.parse(record.request_params)
    rescue JSON::ParserError
      {}
    end
  end
end
