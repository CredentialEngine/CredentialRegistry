# A JSON context payload from CredReg.
class JsonContext < ActiveRecord::Base
  has_paper_trail

  validates :url, :context, presence: true
  validates :url, uniqueness: true

  def self.context
    @@context ||= distinct
      .pluck(:context)
      .map { |c| c.fetch('@context') }
      .inject(&:merge)
  end
end
