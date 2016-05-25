require 'envelope_community'
require 'rsa_decoded_token'
require 'original_user_validator'
require 'json_schema_validator'
require_relative 'extensions/transactionable_envelope'

# Stores an original envelope as received from the user and after being
# processed by the node
class Envelope < ActiveRecord::Base
  extend Forwardable
  include TransactionableEnvelope

  has_paper_trail

  belongs_to :envelope_community

  enum envelope_type: { resource_data: 0 }
  enum resource_format: { json: 0, xml: 1 }
  enum resource_encoding: { jwt: 0 }
  enum node_headers_format: { node_headers_jwt: 0 }

  before_validation :generate_envelope_id, on: :create
  before_validation :process_resource
  after_save :append_headers

  validates :envelope_community, :envelope_type, :envelope_version,
            :envelope_id, :resource, :resource_format, :resource_encoding,
            :processed_resource, presence: true
  validates :envelope_id, uniqueness: true

  # Top level or specific validators
  validates_with OriginalUserValidator, on: :update
  validates_with JSONSchemaValidator, if: :json?

  validate do
    errors.add :resource unless lr_metadata.valid?
  end

  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :with_url, (lambda do |url|
    where('processed_resource @> ?', { url: url }.to_json)
  end)
  scope :in_community, (lambda do |community|
    joins(:envelope_community).where(envelope_communities: { name: community })
  end)

  def_delegator :envelope_community, :name, :community_name

  def lr_metadata
    LearningRegistryMetadata.new(decoded_resource.learning_registry_metadata)
  end

  def decoded_resource
    Hashie::Mash.new(processed_resource)
  end

  def decoded_node_headers
    Hashie::Mash.new(JWT.decode(node_headers, nil, false).first)
  end

  def assign_community(name)
    self.envelope_community = EnvelopeCommunity.find_by(name: name)
  end

  private

  def generate_envelope_id
    self.envelope_id = SecureRandom.uuid unless attribute_present?(:envelope_id)
  end

  def append_headers
    # TODO: sign with some server key?
    update_columns(node_headers: JWT.encode(headers, nil, 'none'),
                   node_headers_format: :node_headers_jwt)
  end

  def process_resource
    self.processed_resource = if json?
                                payload
                              elsif xml?
                                Hash.from_xml(payload[:value])['rdf']
                              end
  end

  def payload
    RSADecodedToken.new(resource, resource_public_key).payload
  end

  def headers
    {
      resource_digest: Digest::SHA256.base64digest(resource),
      created_at: created_at,
      updated_at: updated_at,
      deleted_at: deleted_at,
      versions: versions_header
    }
  end

  def versions_header
    versions.map do |version|
      {
        head: version.next.blank?,
        event: version.event,
        created_at: version.created_at,
        author: version.whodunnit,
        url: version_url(version)
      }
    end
  end

  def version_url(version)
    if version.next.blank?
      "/api/envelopes/#{envelope_id}"
    else
      "/api/envelopes/#{envelope_id}/versions/#{version.next.id}"
    end
  end
end
