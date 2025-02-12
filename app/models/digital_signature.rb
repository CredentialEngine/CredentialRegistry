# Represents the envelope fields related to a digital signature
class DigitalSignature
  include Virtus.model
  include ActiveModel::Validations

  attribute :key_location, [String]

  validates :key_location, presence: true
end
