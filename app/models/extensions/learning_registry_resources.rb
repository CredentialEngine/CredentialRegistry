require 'active_support/concern'
require 'registry_metadata'

# LearningRegistry specific behavior for resource envelopes
module LearningRegistryResources
  extend ActiveSupport::Concern

  included do
    validate do
      if !skip_lr_metadata_validation? && !registry_metadata.valid?
        errors.add :resource, registry_metadata.errors.full_messages
      end
    end

    def registry_metadata
      @registry_metadata ||= RegistryMetadata.new(
        decoded_resource.registry_metadata
      ) if decoded_resource.registry_metadata
    end

    def from_learning_registry?
      community_name == 'learning_registry'
    end

    def skip_lr_metadata_validation?
      !from_learning_registry? || paradata? || registry_metadata.nil?
    end
  end
end
