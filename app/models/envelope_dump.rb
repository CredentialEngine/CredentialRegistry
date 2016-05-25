# Represents a dump file that contains the envelope transactions for a given
# time interval
class EnvelopeDump < ActiveRecord::Base
  validates :provider, :location, :item, presence: true
end
