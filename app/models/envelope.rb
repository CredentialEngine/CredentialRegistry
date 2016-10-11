require 'envelope_community'
require 'rsa_decoded_token'
require 'original_user_validator'
require 'resource_schema_validator'
require 'json_schema_validator'
require 'build_node_headers'
require_relative 'extensions/searchable'
require_relative 'extensions/transactionable_envelope'
require_relative 'extensions/learning_registry_resources'
require_relative 'extensions/ce_registry_resources'

# Stores an original envelope as received from the user and after being
# processed by the node
class Envelope < ActiveRecord::Base
  extend Forwardable
  include Searchable
  include TransactionableEnvelope

  include LearningRegistryResources
  include CERegistryResources

  has_paper_trail

  belongs_to :envelope_community

  enum envelope_type: { resource_data: 0, paradata: 1 }
  enum resource_format: { json: 0, xml: 1 }
  enum resource_encoding: { jwt: 0 }
  enum node_headers_format: { node_headers_jwt: 0 }

  attr_accessor :skip_validation

  before_validation :generate_envelope_id, on: :create
  before_validation :process_resource
  after_save :append_headers

  validates :envelope_community, :envelope_type, :envelope_version,
            :envelope_id, :resource, :resource_format, :resource_encoding,
            :processed_resource, presence: true
  validates :envelope_id, uniqueness: true

  # Top level or specific validators
  validates_with OriginalUserValidator, on: :update
  validates_with ResourceSchemaValidator, if: [:json?, :envelope_community],
                                          unless: [:deleted?, :skip_validation]

  default_scope { where(deleted_at: nil) }
  scope :deleted, -> { unscoped.where.not(deleted_at: nil) }
  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :in_community, (lambda do |community|
    joins(:envelope_community).where(envelope_communities: { name: community })
  end)

  def self.select_scope(include_deleted = nil)
    if include_deleted == 'true'
      unscoped.all
    elsif include_deleted == 'only'
      deleted
    else
      all
    end
  end

  def_delegator :envelope_community, :name, :community_name

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
    if paradata?
      'paradata'
    else
      [community_name, SchemaConfig.resource_type_for(self)].compact.join('/')
    end
  end

  def mark_as_deleted!
    self.deleted_at = Time.current
    save!
  end

  def deleted?
    deleted_at.present?
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
end
