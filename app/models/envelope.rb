require 'rsa_decoded_token'
require 'original_user_validator'

# Stores an original envelope as received from the user and after being
# processed by the node
class Envelope < ActiveRecord::Base
  extend Forwardable

  has_paper_trail

  enum envelope_type: { resource_data: 0 }
  enum resource_format: { json: 0, xml: 1 }
  enum resource_encoding: { jwt: 0 }
  enum node_headers_format: { node_headers_jwt: 0 }

  after_initialize :initialize_decoded_token
  before_validation :generate_envelope_id, on: :create
  before_validation :process_resource, :append_headers

  validates :envelope_type, :envelope_version, :envelope_id, :resource,
            :resource_format, :resource_encoding, :processed_resource,
            presence: true
  validates :envelope_id, uniqueness: true

  # Top level or specific validators
  validates_with OriginalUserValidator, on: :update

  validate do
    errors.add :resource unless lr_metadata.valid?
  end

  scope :ordered_by_date, -> { order(:created_at) }

  def resource=(resource)
    super
    initialize_decoded_token
  end

  def lr_metadata
    LearningRegistryMetadata.new(decoded_resource.learning_registry_metadata)
  end

  def decoded_resource
    Hashie::Mash.new(processed_resource)
  end

  def decoded_node_headers
    Hashie::Mash.new(JWT.decode(node_headers, nil, false).first)
  end

  def_delegators :@rsa_decoded_token, :payload, :decode

  private

  def initialize_decoded_token
    if resource && resource_public_key
      @rsa_decoded_token = RSADecodedToken.new(resource, resource_public_key)
    end
  end

  def generate_envelope_id
    self.envelope_id = SecureRandom.uuid unless attribute_present?(:envelope_id)
  end

  def append_headers
    # TODO: sign with some server key?
    self.node_headers = JWT.encode(headers, nil, 'none')
    self.node_headers_format = :node_headers_jwt
  end

  def process_resource
    self.processed_resource = if json?
                                payload
                              elsif xml?
                                Hash.from_xml(payload[:value])['rdf']
                              end
  end

  def headers
    {
      resource_digest: Digest::SHA256.base64digest(resource)
    }
  end
end
