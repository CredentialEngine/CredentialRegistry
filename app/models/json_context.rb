# A JSON context payload from CredReg.
class JsonContext < ActiveRecord::Base
  has_paper_trail

  validates :url, :context, presence: true
  validates :url, uniqueness: true
end
