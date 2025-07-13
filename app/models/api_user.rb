# Represents a user with their community and roles
class ApiUser
  ADMIN = 'admin'.freeze
  PUBLISHER = 'publisher'.freeze
  READER = 'reader'.freeze

  attr_reader :community, :roles, :user

  delegate :admin, :publisher, to: :user

  def initialize(community:, roles:, user:)
    @community = community
    @roles = Array.wrap(roles)
    @user = user
  end

  def admin?
    roles.include?(ADMIN)
  end

  def publisher?
    admin? || roles.include?(PUBLISHER)
  end

  def reader?
    publisher? || roles.include?(READER)
  end
end
