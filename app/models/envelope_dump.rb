# Represents a dump file that contains the envelope transactions for a given
# time interval
class EnvelopeDump < ActiveRecord::Base
  validates :provider, :location, :item, :dumped_at, presence: true
  validates :dumped_at, uniqueness: true
end
