require_relative 'application_policy'

# Specifies policies for envelopes APIs
class EnvelopePolicy < ApplicationPolicy
  def index?
    user.publisher?
  end

  def create?
    user.publisher?
  end

  def update?
    user.publisher?
  end

  def destroy?
    user.publisher?
  end
end
