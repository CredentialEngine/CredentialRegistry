require_relative 'application_policy'

# Specifies policies for envelope community config API
class EnvelopeCommunityConfigPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def show?
    user.admin?
  end
end
