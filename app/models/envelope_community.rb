# frozen_string_literal: true

# Represents a metadata community that acts as a scope for envelope related
# operations
class EnvelopeCommunity < ActiveRecord::Base
  has_many :envelopes

  validates :name, presence: true, uniqueness: true
  validates :default, uniqueness: true, if: :default

  def self.default
    where(default: true).first
  end

  def self.host_mapped(host)
    host_mappings[host]
  end

  def config(type = nil)
    @config ||= JSON.parse File.read(config_path)
    type.present? ? @config[type] : @config
  rescue Errno::ENOENT
    raise MR::SchemaDoesNotExist, name
  end

  def skip_validation_enabled?
    config['skip_validation_enabled']
  end

  def id_prefix
    config['id_prefix']
  end

  def id_field
    config['id_field']
  end

  def ce_registry?
    name =~ /ce_registry/
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
      if ce_registry?
        res_type = envelope.processed_resource['@type'] || \
                   envelope.processed_resource.dig('@graph', 0, '@type')
        return res_type if res_type.present?
      end

      raise MR::SchemaDoesNotExist,
            "Cannot load json-schema. #{cfg['property']} is required"
    end

    cfg['values_map'].fetch(key) do
      raise MR::SchemaDoesNotExist,
            "Cannot load json-schema. The property '#{cfg['property']}' "\
            "has an invalid value '#{key}'"
    end
  end
end
