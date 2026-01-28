require_relative 'application_policy'

# Specifies policies for workflow operations
class WorkflowPolicy < ApplicationPolicy
  def trigger?
    user.admin?
  end

  def show?
    user.admin?
  end
end
