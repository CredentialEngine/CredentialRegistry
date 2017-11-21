# Represents a particular user of both admin and publisher accounts
class User < ActiveRecord::Base
  belongs_to :admin
  belongs_to :publisher
  has_many :auth_tokens

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :account_presence

  normalize_attribute :email do |value|
    value.is_a?(String) ? value.gsub(/[[:space:]]/, '') : value
  end

  after_create :create_auth_token

  def admin?
    admin.present?
  end

  def auth_token
    auth_tokens.first
  end

  private

  def account_presence
    return if admin.present? || publisher.present?

    errors.add(:base, 'Either admin or publisher must be present')
  end

  def create_auth_token
    auth_tokens.create!
  end
end
