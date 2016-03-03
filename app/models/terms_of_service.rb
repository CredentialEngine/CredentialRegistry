# Represents the envelope fields related to terms of service
class TermsOfService
  include Virtus.model
  include ActiveModel::Validations

  attribute :submission_tos, String

  validates :submission_tos, presence: true
end
