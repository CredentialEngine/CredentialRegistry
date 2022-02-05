# Represents a description set for a resource:
# an array of the URIs of the related resources connected to the given resource
# by a certain property path
class DescriptionSet < ActiveRecord::Base
  belongs_to :envelope_community
  belongs_to :envelope_resource
end
