# The custom subclass of PaperTrail::Version for envelopes
class EnvelopeVersion < PaperTrail::Version
  enum :publication_status, MR.envelope_publication_statuses

  has_many :envelopes, primary_key: :item_id, foreign_key: :id

  scope :with_provisional_publication_status, lambda { |value|
    case value
    when 'only'
      provisional
    when 'include'
      all
    else
      full
    end
  }
end
