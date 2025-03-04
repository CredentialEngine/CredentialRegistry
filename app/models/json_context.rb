# A JSON context payload from CredReg.
class JsonContext < ActiveRecord::Base
  has_paper_trail

  validates :url, :context, presence: true
  validates :url, uniqueness: true

  class << self
    def context
      {
        'ceterms:ctid' => { '@type' => 'xsd:string' },
        'search:recordCreated' => { '@type' => 'xsd:dateTime' },
        'search:recordUpdated' => { '@type' => 'xsd:dateTime' }
      }.merge(
        distinct
          .pluck(:context)
          .map { |c| c.fetch('@context') }
          .inject(&:merge) || {}
      )
    end

    def update(url)
      context = JSON.parse(RestClient.get(url).body)
      json_context = JsonContext.find_or_initialize_by(url:)
      json_context.update!(context:)
    end
  end
end
