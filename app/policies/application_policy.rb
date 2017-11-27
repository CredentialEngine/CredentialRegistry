# Base policy; other policies inherit from it
class ApplicationPolicy
  attr_reader :user

  def initialize(user, _)
    @user = user
  end
end
