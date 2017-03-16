# Represents a metadata community that acts as a scope for envelope related
# operations
class EnvelopeCommunity < ActiveRecord::Base
  has_many :envelopes

  validates :name, presence: true, uniqueness: true
  validates :default, uniqueness: true, if: :default

  def self.default
    where(default: true).first
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

  private

  def config_path
    File.join(MR.fixtures_path, 'configs', "#{name}.json")
  end

  def get_resource_type_from_values_map(cfg, envelope)
    key = envelope.processed_resource.fetch(cfg['property']) do
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
