require_relative 'application_policy'

# Specifies policies for organization API
class EnvelopeCommunityPolicy < ApplicationPolicy
  def create?
    return true if user.superadmin?

    user.admin? && record == user.community
  end
end
