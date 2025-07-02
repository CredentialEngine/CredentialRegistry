require_relative 'application_policy'

# Specifies policies for envelope resource APIs
class EnvelopeResourcePolicy < ApplicationPolicy
  def index?
    user.reader?
  end

  def create?
    user.publisher?
  end
end
