module API
  module Entities
    # Presenter for the envelope community config
    class EnvelopeCommunityConfig < Grape::Entity
      expose :description
      expose :payload
    end
  end
end
