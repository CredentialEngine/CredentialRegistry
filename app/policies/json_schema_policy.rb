require_relative 'application_policy'

# Specifies policies for JSON Schema API
class JsonSchemaPolicy < ApplicationPolicy
  def create?
    user.admin?
  end
end
