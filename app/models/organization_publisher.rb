# Join model used for whitelisting publishers for certain organizations
class OrganizationPublisher < ActiveRecord::Base
  belongs_to :organization
  belongs_to :publisher
  has_many :key_pairs

  after_create :create_key_pair

  private

  def create_key_pair
    key_pairs.create!
  end
end
