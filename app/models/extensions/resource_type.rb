# Assigns a resource type to an envelope or envelope resource
module ResourceType
  extend ActiveSupport::Concern

  included do
    before_save :set_resource_type

    def set_resource_type
      return unless resource_data?

      self.resource_type = envelope_community&.resource_type_for(self)
    end
  end
end
