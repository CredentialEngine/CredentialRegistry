require 'entities/description_set_group'

module API
  module Entities
    # Presenter for description set collections
    class DescriptionSetData < Grape::Entity
      expose :description_sets, using: DescriptionSetGroup

      expose :resources,
             as: :description_set_resources,
             unless: ->(object) { object.resources.nil? }
    end
  end
end
