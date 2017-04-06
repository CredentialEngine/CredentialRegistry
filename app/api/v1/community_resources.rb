module API
  module V1
    # Implements all the endpoints related to resources
    class CommunityResources < Grape::API
      include API::V1::ResourceAPI
      params { use :envelope_community }
    end
  end
end
