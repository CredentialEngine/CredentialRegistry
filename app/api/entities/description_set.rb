module API
  module Entities
    # Presenter for the description set
    class DescriptionSet < Grape::Entity
      expose :path
      expose :total
      expose :uris
    end
  end
end
