# A JSON context payload from CredReg.
class JsonContext < ActiveRecord::Base
  has_paper_trail

  validates :url, :context, presence: true
  validates :url, uniqueness: true

  def self.context
    distinct
      .pluck(:context)
      .map { |c| c.fetch('@context') }
      .inject(&:merge)
      .merge(
        'ceterms:ctid' => { '@type' => 'xsd:string' },
        'search:recordCreated' => { '@type' => 'xsd:dateTime' },
        'search:recordUpdated' => { '@type' => 'xsd:dateTime' },
      )
  end
end
