# Represents the envelope fields related to identity
class Identity
  include Virtus.model
  include ActiveModel::Validations

  attribute :submitter_type, String
  attribute :submitter, String
  attribute :signer, String

  validates :submitter_type, :submitter, presence: true
  validates :submitter_type, inclusion: { in: %w(anonymous user agent) }
end
