require 'entities/description_set_group'

module API
  module Entities
    # Presenter for description set collections
    class DescriptionSetData < Grape::Entity
      expose :description_sets, using: DescriptionSetGroup

      expose :resources,
             as: :description_set_resources,
             if: ->(object) { object.resources }

      expose :results_metadata, if: ->(object) { object.results_metadata }
    end
  end
end
