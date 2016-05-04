module API
  module Entities
    # Presenter for the envelope community
    class EnvelopeCommunity < Grape::Entity
      expose :name, as: :envelope_community
    end
  end
end
