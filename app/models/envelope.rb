require 'envelope_community'
require 'rsa_decoded_token'
require 'registry_metadata'
require 'original_user_validator'
require 'resource_schema_validator'
require 'json_schema_validator'
require 'build_node_headers'
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
  validates_with ResourceSchemaValidator, if: [:json?, :envelope_community]

  validate do
    if from_learning_registry? && !registry_metadata.valid?
      errors.add :resource, registry_metadata.errors
    end
  end

  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :with_url, (lambda do |url|
    where('processed_resource @> ?', { url: url }.to_json)
  end)
  scope :in_community, (lambda do |community|
    joins(:envelope_community).where(envelope_communities: { name: community })
  end)

  def_delegator :envelope_community, :name, :community_name

  def registry_metadata
    @registry_metadata ||= RegistryMetadata.new(
      decoded_resource.registry_metadata
    )
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

  def resource_schema_name
    # community_name comes from the `envelope_community` association,
    # i.e: the name is an already validated entry on our database
    comm_name = community_name
    # credential_registry => credential_registry_schema
    custom_method = :"#{comm_name}_schema"

    # for customizing the schema name for specific communities we just have
    # to define a method `<community_name>_schema`
    respond_to?(custom_method, true) ? send(custom_method) : comm_name
  end

  def from_learning_registry?
    community_name == 'learning_registry'
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
    BuildNodeHeaders.new(self).headers
  end

  # specific schema name for credential-registry resources
  def credential_registry_schema
    # @type: "cti:Organization" | "cti:Credential"
    cti_type = processed_resource['@type']
    if cti_type
      # "cti:Organization" => 'credential_registry/organization'
      "credential_registry/#{cti_type.gsub('cti:', '').underscore}"
    else
      errors.add :resource, 'Invalid resource @type'
    end
  end
end
