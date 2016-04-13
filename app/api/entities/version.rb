module API
  module Entities
    # Presenter for an Envelope Version
    class Version < Grape::Entity
      expose :id
      expose :event
      expose :whodunnit, as: :actor
      expose :url do |version|
        "/api/envelopes/#{version.reify.envelope_id}/versions/#{version.id}"
      end
    end
  end
end
