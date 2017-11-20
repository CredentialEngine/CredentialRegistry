require_relative 'application_policy'

# Specifies policies for user API
class UserPolicy < ApplicationPolicy
  def create?
    user.admin?
  end
end
