require 'envelope_community'
require 'rsa_decoded_token'
require 'original_user_validator'
require 'resource_schema_validator'
require 'json_schema_validator'
require 'build_node_headers'
require 'authorized_key'
require 'set'
require_relative 'extensions/transactionable_envelope'
require_relative 'extensions/learning_registry_resources'
require_relative 'extensions/ce_registry_resources'
require_relative 'extensions/gremlin_indexable'
require_relative 'extensions/resource_type'

# Stores an original envelope as received from the user and after being
# processed by the node
# rubocop:disable Metrics/ClassLength
class Envelope < ActiveRecord::Base
  extend Forwardable
  include TransactionableEnvelope
  include LearningRegistryResources
  include CERegistryResources
  include GremlinIndexable
  include ResourceType

  has_paper_trail on: %i[create update]

  belongs_to :envelope_community
  belongs_to :organization
  belongs_to :publishing_organization, class_name: 'Organization'
  belongs_to :publisher
  has_many :envelope_resources, dependent: :destroy
  has_many :indexed_envelope_resources, through: :envelope_resources
  alias community envelope_community

  enum envelope_type: { resource_data: 0, paradata: 1, json_schema: 2 }
  enum resource_format: { json: 0, xml: 1 }
  enum resource_encoding: { jwt: 0 }
  enum node_headers_format: { node_headers_jwt: 0 }

  attr_accessor :skip_validation

  before_validation :generate_envelope_id, on: :create
  before_validation :process_resource, :process_headers
  after_save :update_headers
  before_destroy :delete_versions
  after_commit :delete_indexed_envelope_resources

  validates :envelope_community, :envelope_type, :envelope_version,
            :envelope_id, :resource, :resource_format, :resource_encoding,
            :processed_resource, presence: true
  validates :envelope_id, uniqueness: true

  # Top level or specific validators
  validates_with OriginalUserValidator, on: :update
  validates_with ResourceSchemaValidator, if: %i[json? envelope_community],
                                          unless: %i[deleted? skip_validation]

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :in_community, (lambda do |community|
    return unless community
    joins(:envelope_community).where(envelope_communities: { name: community })
  end)
  scope :with_graph, -> { where("(processed_resource->'@graph') IS NOT NULL") }

  NOT_FOUND = 'Envelope not found'.freeze
  DELETED = 'Envelope deleted'.freeze

  def self.by_top_level_object_id(id)
    return nil unless id.present?
    find_by('top_level_object_ids @> ARRAY[?]', id.downcase)
  end

  def self.by_resource_id(id)
    return nil unless id.present?
    find_by('processed_resource @> ?', { '@id' => id }.to_json)
  end

  def self.community_resource(community_name, id)
    community = EnvelopeCommunity.find_by(name: community_name)

    if community&.id_field.present?
      resource = in_community(community_name).by_top_level_object_id(id)
      return resource if resource
    end

    prefix = community&.id_prefix
    in_community(community_name).by_resource_id(id) ||
      in_community(community_name).by_resource_id("#{prefix}#{id}")
  end

  def self.select_scope(include_deleted = nil)
    if include_deleted == 'true'
      all
    elsif include_deleted == 'only'
      deleted
    else
      not_deleted
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
    elsif json_schema?
      'json_schema'
    else
      [community_name, resource_type].compact.join('/')
    end
  end

  def resource_type
    @resource_type || community.resource_type_for(self)
  end

  def mark_as_deleted!(purge = false)
    current = Time.current
    self.deleted_at = current
    self.purged_at = current if purge
    save!
  end

  def deleted?
    deleted_at.present?
  end

  def process_headers
    self.node_headers = JWT.encode(headers, nil, 'none')
    self.node_headers_format = :node_headers_jwt
  end

  def process_resource
    self.processed_resource = xml? ? parse_xml_payload : payload
    self.top_level_object_ids = parse_top_level_object_ids
    self.envelope_ceterms_ctid = processed_resource_ctid if ce_registry?
    processed_resource
  end

  def id_field
    custom_id_field = envelope_community.id_field
    custom_id_field.present? ? custom_id_field : '@id'
  end

  def inner_resource_from_graph(id)
    return processed_resource unless processed_resource_graph
    from_graph = processed_resource_graph.find { |graph_obj| graph_obj[id_field] == id.downcase }
    return processed_resource unless from_graph
    from_graph.merge('@context' => processed_resource['@context'])
  end

  def processed_resource_graph
    processed_resource['@graph']
  end

  def processed_resource_id
    processed_resource[id_field]
  end

  def processed_resource_ctid
    processed_resource['@id'].to_s.split('/').last.presence&.downcase
  end

  private

  def generate_envelope_id
    self.envelope_id = SecureRandom.uuid unless attribute_present?(:envelope_id)
  end

  # Updates the headers after save to account for the newly-created papertrail version.
  def update_headers
    process_headers

    # TODO: sign with some server key?
    update_columns(node_headers: node_headers)
  end

  def payload
    if json_schema?
      authorized_key = AuthorizedKey.new(community_name, resource_public_key)
      raise MR::UnauthorizedKey unless authorized_key.valid?
    end
    RSADecodedToken.new(resource, resource_public_key).payload
  end

  def parse_xml_payload
    Hash.from_xml(payload[:value])['rdf']
  end

  # rubocop:disable Metrics/AbcSize
  def parse_top_level_object_ids
    ctids = Set.new
    ctids << processed_resource_id unless processed_resource_id.blank?

    # Skip blank nodes (bnodes - ID starts with '_').
    Array.wrap(processed_resource_graph).each do |graph_obj|
      graph_obj_id = graph_obj[id_field]
      next if graph_obj_id.blank? || graph_obj_id.start_with?('_')
      ctids << graph_obj_id
    end

    ctids.map(&:downcase)
  end

  def headers
    BuildNodeHeaders.new(self).headers
  end

  def delete_versions
    versions.destroy_all
  end

  def delete_indexed_envelope_resources
    return unless deleted_at? && previous_changes.key?('deleted_at')

    IndexedEnvelopeResource
      .where(id: indexed_envelope_resources.select(:id))
      .delete_all
  end
end
