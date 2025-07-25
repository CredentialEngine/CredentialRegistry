# frozen_string_literal: true

# Represents a metadata community that acts as a scope for envelope related
# operations
class EnvelopeCommunity < ActiveRecord::Base
  include AttributeNormalizer

  has_one :envelope_community_config
  has_many :envelope_downloads
  has_many :envelopes
  has_many :envelope_resources, through: :envelopes
  has_many :indexed_envelope_resources

  validates :name, presence: true, uniqueness: true
  validates :default, uniqueness: true, if: :default

  normalize_attribute :name, with: %i[downcase remove_spaces underscore]

  def self.default
    where(default: true).first
  end

  def self.host_mapped(host)
    host_mappings[host]
  end

  def config(type = nil)
    @config ||= envelope_community_config&.payload ||
                JSON.parse(File.read(config_path))

    type.present? ? @config[type] : @config
  rescue Errno::ENOENT
    raise MR::SchemaDoesNotExist, name
  end

  def skip_validation_enabled?
    config['skip_validation_enabled']
  end

  def id_prefix
    config['id_prefix'].presence
  end

  def id_field
    config['id_field'].presence
  end

  def ce_registry?
    name.include?('ce_registry')
  end

  # get the resource_type for the envelope from the community config (if exists)
  # Ex:
  #   1) resource_type is a string
  #   config: {"resource_type": "@type"}
  #   processed_resource: "@type"='Bla'
  #   >> 'Bla'
  #
  #   2) resource_type is an object with mapped values
  #   config: {"resource_type": {
  #             "property": "@type", "values_map": {"abc:Bla": 'bla'}
  #            }}
  #   processed_resource: "@type"='abc:Bla'
  #   >> 'bla'
  def resource_type_for(envelope)
    cfg = config.try(:[], 'resource_type')
    return nil if cfg.blank?

    if cfg.is_a?(String)
      envelope.processed_resource[cfg]
    else
      get_resource_type_from_values_map(cfg, envelope)
    end
  end

  def self.host_mappings
    @host_mappings ||= JSON.parse(
      File.read(MR.root_path.join('config', 'envelope_communities.json'))
    )
  rescue Errno::ENOENT
    {}
  rescue JSON::ParserError
    MR.logger.error('envelope_communities.json is not valid JSON')
    {}
  end

  private

  def config_path
    MR.root_path.join('fixtures', 'configs', "#{name}.json")
  end

  def get_resource_type_from_values_map(cfg, envelope)
    key = envelope.processed_resource.fetch(cfg['property']) do
      res_type = envelope.processed_resource['@type'] ||
                 envelope.processed_resource.dig('@graph', 0, '@type')

      if res_type.present?
        res_type
      else
        raise MR::SchemaDoesNotExist,
              "Cannot load json-schema. #{cfg['property']} is required"
      end
    end

    cfg['values_map'].fetch(key) do
      raise MR::SchemaDoesNotExist,
            "Cannot load json-schema. The property '#{cfg['property']}' " \
            "has an invalid value '#{key}'"
    end
  end
end
