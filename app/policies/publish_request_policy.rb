require_relative 'application_policy'

class PublishRequestPolicy < ApplicationPolicy
  def show?
    return true if user.superadmin?

    request_user_id = parsed_params['user_id']
    return true if request_user_id && user.user&.id.to_s == request_user_id.to_s

    # Allow if it belongs to the same community (either via envelope or params)
    env_comm_id = record.envelope&.envelope_community_id || parsed_params['envelope_community_id']
    env_comm_id && user.community&.id.to_s == env_comm_id.to_s
  end

  class Scope < Struct.new(:user, :scope)
    def resolve
      # Keep default scope unchanged; endpoints should authorize per-record.
      scope
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

