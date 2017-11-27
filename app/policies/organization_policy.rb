require_relative 'application_policy'

# Specifies policies for organization API
class OrganizationPolicy < ApplicationPolicy
  def create?
    user.admin?
  end
end
