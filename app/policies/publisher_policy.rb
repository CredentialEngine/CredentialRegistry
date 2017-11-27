require_relative 'application_policy'

# Specifies policies for publisher API
class PublisherPolicy < ApplicationPolicy
  def create?
    user.admin?
  end
end
