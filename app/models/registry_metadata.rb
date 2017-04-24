require 'digital_signature'
require 'terms_of_service'
require 'identity'

# Virtual model that represents the fields inside an envelope
# TODO keep adding attributes until complete (http://docs.learningregistry.org/en/latest/spec/Resource_Data_Data_Model/index.html#resource-data-description-data-model)
class RegistryMetadata
  include Virtus.model
  include ActiveModel::Validations

  attribute :digital_signature, DigitalSignature
  attribute :keys, Array
  attribute :terms_of_service, TermsOfService
  attribute :payload_placement, String
  attribute :identity, Identity

  validates :payload_placement, presence: true,
                                inclusion: { in: %w[inline linked attached] }

  validate do
    errors.add :digital_signature unless digital_signature.valid?
    errors.add :terms_of_service unless terms_of_service.valid?
    errors.add :identity unless identity.valid?
  end

  def initialize(attributes)
    self.digital_signature ||= DigitalSignature.new
    self.terms_of_service ||= TermsOfService.new
    self.identity ||= Identity.new

    super
  end
end
