# Join model used for whitelisting publishers for certain organizations
class OrganizationPublisher < ActiveRecord::Base
  belongs_to :organization
  belongs_to :publisher

  validates :organization, presence: true
  validates :publisher, presence: true
end
