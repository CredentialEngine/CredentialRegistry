require 'admin'

# The account able to publish resources
class Publisher < ActiveRecord::Base
  belongs_to :admin
  has_many :organization_publishers
  has_many :organizations, through: :organization_publishers

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalize_attribute :name, with: :squish
end
