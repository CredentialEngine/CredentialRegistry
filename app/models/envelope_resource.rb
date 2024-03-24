require 'ostruct'
require_relative 'extensions/resource_type'
require_relative 'extensions/searchable'

# A JSON-LD object stored in an envelope.
class EnvelopeResource < ActiveRecord::Base
  extend Forwardable
  include ResourceType
  include Searchable

  belongs_to :envelope
  belongs_to :envelope_community, optional: true
  has_many :description_sets
  has_many :indexed_envelope_resources

  enum envelope_type: { resource_data: 0, paradata: 1, json_schema: 2 }

  scope :not_deleted, -> { joins(:envelope).where(envelopes: { deleted_at: nil }) }
  scope :deleted, -> { joins(:envelope).where.not(envelopes: { deleted_at: nil }) }

  scope :in_community, (lambda do |community|
    return unless community
    joins(envelope: :envelope_community).where(envelope_communities: { name: community })
  end)

  before_save do
    self.envelope_community_id ||= envelope&.envelope_community_id
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

  def envelope_community
    super || envelope&.envelope_community
  end

  # get the search configuration schema
  def search_configuration
    @search_configuration ||= begin
      set_resource_type

      config = envelope_community.config(resource_type)&.[]('fts') || {}
      OpenStruct.new(config.slice('full', 'partial'))
    rescue MR::SchemaDoesNotExist
      nil
    end
  end
end
