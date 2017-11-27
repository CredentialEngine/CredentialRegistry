# Organization on whose behalf publishing is done
class Organization < ActiveRecord::Base
  belongs_to :admin
  has_many :organization_publishers
  has_many :publishers, through: :organization_publishers
  has_many :key_pairs

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :admin, presence: true

  normalize_attribute :name, with: :squish

  after_create :create_key_pair

  def key_pair
    key_pairs.first
  end

  private

  def create_key_pair
    key_pairs.create!
  end
end
