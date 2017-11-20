# Organization on whose behalf publishing is done
class Organization < ActiveRecord::Base
  belongs_to :admin
  has_many :organization_publishers
  has_many :publishers, through: :organization_publishers

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :admin, presence: true

  normalize_attribute :name, with: :squish
end
