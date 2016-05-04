# Represents a metadata community that acts as a scope for envelope related
# operations
class EnvelopeCommunity < ActiveRecord::Base
  has_many :envelopes

  validates :name, presence: true, uniqueness: true
  validates :default, uniqueness: true, if: :default

  def self.default
    where(default: true).first
  end
end
