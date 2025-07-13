# Base policy; other policies inherit from it
class ApplicationPolicy
  attr_reader :record, :user

  def initialize(user, record)
    @record = record
    @user = user
  end
end
