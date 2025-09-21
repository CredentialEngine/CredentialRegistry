# The custom subclass of PaperTrail::Version for envelopes
class EnvelopeVersion < PaperTrail::Version
  enum :publication_status, MR.envelope_publication_statuses

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
