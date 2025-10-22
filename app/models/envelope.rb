require 'envelope_community'
require 'build_node_headers'
require 'authorized_key'
require 'export_to_ocn_job'
require 'delete_from_ocn_job'
require 'envelope_version'
require_relative 'extensions/transactionable_envelope'
require_relative 'extensions/learning_registry_resources'
require_relative 'extensions/ce_registry_resources'
require_relative 'extensions/resource_type'

# Stores an original envelope as received from the user and after being
# processed by the node
# rubocop:todo Lint/MissingCopEnableDirective
# rubocop:disable Metrics/ClassLength
# rubocop:enable Lint/MissingCopEnableDirective
class Envelope < ActiveRecord::Base
  extend Forwardable
  include TransactionableEnvelope
  include LearningRegistryResources
  include CERegistryResources
  include ResourceType

  has_paper_trail meta: {
                    envelope_ceterms_ctid: :envelope_ceterms_ctid,
                    envelope_community_id: :envelope_community_id,
                    publication_status: :publication_status
                  },
                  versions: { class_name: 'EnvelopeVersion' }

  belongs_to :envelope_community
  belongs_to :organization
  belongs_to :publishing_organization, class_name: 'Organization'
  belongs_to :publisher
  has_many :envelope_resources, dependent: :destroy
  has_many :description_sets, through: :envelope_resources
  has_many :indexed_envelope_resources, through: :envelope_resources

  enum :envelope_type, { resource_data: 0, paradata: 1, json_schema: 2 }
  enum :resource_format, { json: 0, xml: 1 }
  enum :resource_encoding, { jwt: 0 }
  enum :node_headers_format, { node_headers_jwt: 0 }
  enum :publication_status, MR.envelope_publication_statuses

  before_validation :generate_envelope_id, on: :create
  before_validation :process_resource, :process_headers
  before_save :assign_last_verified_on
  after_save :update_headers
  after_save :upload_to_s3
  before_destroy :delete_description_sets, prepend: true
  after_destroy :delete_from_ocn
  after_destroy :delete_from_s3
  after_commit :export_to_ocn

  validates :envelope_community, :envelope_type, :envelope_version,
            :envelope_id, :resource_format, :resource_encoding,
            :processed_resource, presence: true
  validates :envelope_id, uniqueness: true

  RESOURCE_PUBLISH_TYPES = %w[primary secondary].freeze
  validates :resource_publish_type, inclusion: { in: RESOURCE_PUBLISH_TYPES, allow_blank: true }

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :in_community, (lambda do |community|
    return unless community

    joins(:envelope_community).where(envelope_communities: { name: community })
  end)
  scope :with_graph, -> { where("(processed_resource->'@graph') IS NOT NULL") }
  scope :with_provisional_publication_status, lambda { |value|
    case value
    when 'only'
      provisional
    when 'include'
      all
    else
      full
    end
  }

  NOT_FOUND = 'Envelope not found'.freeze
  DELETED = 'Envelope deleted'.freeze

  def self.by_top_level_object_id(id)
    return nil unless id.present?

    find_by('top_level_object_ids @> ARRAY[?]', id.downcase)
  end

  def self.by_resource_id(id)
    return nil unless id.present?

    find_by("LOWER(processed_resource->>'@id') = ?", id.downcase)
  end

  def self.community_resource(community_name, id)
    community = EnvelopeCommunity.find_by(name: community_name)
    return unless community

    envelopes = in_community(community_name)

    (envelopes.by_top_level_object_id(id) if community.id_field) ||
      envelopes.by_resource_id(id) ||
      envelopes.by_resource_id("#{community.id_prefix}#{id}")
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

  def envelope_community_name
    envelope_community.name
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
    if paradata?
      'paradata'
    elsif json_schema?
      'json_schema'
    else
      [envelope_community.name, resource_type].compact.join('/')
    end
  end

  def resource_type
    @resource_type ||= envelope_community&.resource_type_for(self)
  end

  def mark_as_deleted!
    transaction do
      current = Time.current
      self.deleted_at = current
      save!
      delete_description_sets

      IndexedEnvelopeResource
        .where(id: indexed_envelope_resources.select(:id))
        .delete_all
    end
  end

  def deleted?
    deleted_at.present?
  end

  def process_headers
    self.node_headers = JWT.encode(headers, nil, 'none')
    self.node_headers_format = :node_headers_jwt
  end

  def process_resource
    self.top_level_object_ids = parse_top_level_object_ids
    self.envelope_ceterms_ctid = processed_resource_ctid if ce_registry?

    self.publication_status =
      if processed_resource['adms:status'] == 'graphPublicationStatus:Provisional'
        :provisional
      else
        :full
      end

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
    processed_resource[id_field] ||
      processed_resource['@id'].to_s.split('/').last.presence&.downcase
  end

  private

  def assign_last_verified_on
    actual_changes = changes.except('last_verified_on', 'updated_at')
    self.last_verified_on = Date.current if actual_changes.any?
  end

  def generate_envelope_id
    self.envelope_id = SecureRandom.uuid unless attribute_present?(:envelope_id)
  end

  # Updates the headers after save to account for the newly-created papertrail version.
  def update_headers
    process_headers

    # TODO: sign with some server key?
    update_columns(node_headers: node_headers)
  end

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

  def delete_description_sets
    PrecalculateDescriptionSets.delete_description_sets(self)
  end

  def delete_from_ocn
    return unless envelope_community.ocn_export_enabled?

    DeleteFromOCNJob.perform_later(envelope_ceterms_ctid, envelope_community_id)
  end

  def export_to_ocn
    return unless envelope_community.ocn_export_enabled?

    ExportToOCNJob.perform_later(id)
  end

  def upload_to_s3
    SyncEnvelopeGraphWithS3.upload(self)
  end

  def delete_from_s3
    SyncEnvelopeGraphWithS3.remove(self)
  end
end
