module API
  module Entities
    # Presenter for the envelope community
    class EnvelopeCommunity < Grape::Entity
      expose :name
      expose :default
      expose :secured
      expose :secured_search
    end
  end
end
