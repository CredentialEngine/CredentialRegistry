require 'original_user_validator'

# Stores an original document as received from the user and after being
# processed by the node
class Document < ActiveRecord::Base
  enum doc_type: { resource_data: 0 }
  enum user_envelope_format: { json: 0, xml: 1 }
  enum node_headers_format: { jwt: 0 }

  before_validation :generate_doc_id, on: :create
  before_validation :process_envelope
  before_validation :append_headers

  validates :doc_type, :doc_version, :doc_id, :user_envelope,
            :user_envelope_format, :processed_envelope, presence: true
  validates :doc_id, uniqueness: true

  # Top level or specific validators
  validates_with OriginalUserValidator, on: :update

  validate do
    errors.add :user_envelope unless lr_metadata.valid?
  end

  scope :ordered_by_date, -> { order(:created_at) }

  def lr_metadata
    LearningRegistryMetadata.new(processed_envelope.learning_registry_metadata)
  end

  def decoded_envelope
    Hashie::Mash.new(JWT.decode(user_envelope, nil, false).first)
  end

  def decoded_node_headers
    Hashie::Mash.new(JWT.decode(node_headers, nil, false).first)
  end

  def processed_envelope
    Hashie::Mash.new(read_attribute(:processed_envelope))
  end

  private

  def process_envelope
    self.processed_envelope = if json?
                                decoded_envelope
                              elsif xml?
                                Hash.from_xml(decoded_envelope.value)['rdf']
                              end
  end

  def generate_doc_id
    self.doc_id = SecureRandom.uuid unless attribute_present?(:doc_id)
  end

  def append_headers
    self.node_headers = JWT.encode(headers, nil, 'none')
    self.node_headers_format = :jwt
  end

  def headers
    {
      user_envelope_digest: Digest::SHA256.base64digest(user_envelope)
    }
  end
end
