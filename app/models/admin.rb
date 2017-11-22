# The account able to manage organization, publishers and their users
class Admin < ActiveRecord::Base
  has_many :organizations
  has_many :publishers

  validates :name, presence: true
end
