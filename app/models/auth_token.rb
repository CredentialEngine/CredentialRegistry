require 'user'

# Stores values for token-based authentication
class AuthToken < ActiveRecord::Base
  belongs_to :user
  has_one :admin, through: :user

  before_create :generate_value

  def generate_value
    loop do
      self.value = SecureRandom.hex
      break unless AuthToken.exists?(value: value)
    end
  end
end
