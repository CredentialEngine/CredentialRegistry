module API
  module V1
    # Implements all the endpoints related to envelopes
    class CommunityEnvelopes < Grape::API
      include API::V1::EnvelopeAPI
      params { use :envelope_community }
    end
  end
end
