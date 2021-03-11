# Represents an envelope community's configuration
class EnvelopeCommunityConfig < ActiveRecord::Base
  has_paper_trail

  belongs_to :envelope_community

  validates :description, :payload, presence: true
end
