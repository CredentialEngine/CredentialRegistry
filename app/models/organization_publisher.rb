require 'key_pair'

# Join model used for whitelisting publishers for certain organizations
class OrganizationPublisher < ActiveRecord::Base
  belongs_to :organization
  belongs_to :publisher
  has_many :key_pairs

  validates :organization, presence: true
  validates :publisher, presence: true

  after_create :create_key_pair

  def key_pair
    key_pairs.first
  end

  private

  def create_key_pair
    key_pairs.create!
  end
end
