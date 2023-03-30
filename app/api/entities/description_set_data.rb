require 'entities/description_set_group'

module API
  module Entities
    # Presenter for description set collections
    class DescriptionSetData < Grape::Entity
      expose :resources, as: :data

      expose :description_set_groups,
             as: :description_sets,
             using: DescriptionSetGroup

      expose :subresources,
             as: :description_set_resources,
             if: ->(object) { object.subresources }

      expose :results_metadata, if: ->(object) { object.results_metadata }
    end
  end
end
