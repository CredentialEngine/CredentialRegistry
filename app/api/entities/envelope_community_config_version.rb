require 'entities/envelope_community_config'

module API
  module Entities
    # Presenter for the envelope community config
    class EnvelopeCommunityConfigVersion < Grape::Entity
      expose :id
      expose :created_at, as: :changed_at
      expose :object, as: :previous_version, using: EnvelopeCommunityConfig
      expose :diff

      def diff
        object.changeset.slice(:description, :payload)
      end
    end
  end
end
