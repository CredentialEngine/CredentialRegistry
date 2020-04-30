require 'admin'
require 'organization_publisher'

# The account able to publish resources
class Publisher < ActiveRecord::Base
  belongs_to :admin
  has_many :organization_publishers
  has_many :organizations, through: :organization_publishers

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :admin, presence: true

  normalize_attribute :name, with: :squish

  NOT_AUTHORIZED_TO_PUBLISH =
    'Publisher is not authorized to publish on behalf of this organization'.freeze

  def self.find_by_token(token)
    token = AuthToken.find_by(value: token)

    return nil unless token

    token.user.publisher
  end

  def authorized_to_publish?(organization)
    authorized = OrganizationPublisher
                 .where(organization: organization)
                 .where(publisher: self)
                 .exists?

    # if the publisher is already authorized to publish on behalf of this
    # organization, great
    return true if authorized

    # if not, and the publisher is not a super publisher, bail
    return false unless super_publisher?

    # super publisher get an OrganizationPublisher record created on the fly,
    # authorizing them to publish on behalf of this organization now and in the
    # future
    organization_publishers.create!(organization: organization) if organization
    true
  end
end
