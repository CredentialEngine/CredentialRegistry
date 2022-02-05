# Assigns a resource type to an envelope or envelope resource
module ResourceType
  extend ActiveSupport::Concern

  included do
    before_save :set_resource_type

    def set_resource_type
      return if envelope_community.blank?
      return resource_type if resource_type?

      self.resource_type = envelope_community.resource_type_for(self) if resource_data?
    end
  end
end
