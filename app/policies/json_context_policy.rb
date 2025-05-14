require_relative 'application_policy'

# Specifies policies for organization API
class JsonContextPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.admin?
  end
end
