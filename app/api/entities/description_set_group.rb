require 'entities/description_set'

module API
  module Entities
    # Presenter for description sets grouped by the CTID
    class DescriptionSetGroup < Grape::Entity
      expose :ctid
      expose :description_set, using: DescriptionSet
    end
  end
end
