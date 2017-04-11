module API
  module V1
    # Implements all the endpoints related to resources
    class CommunityResources < Grape::API
      include API::V1::ResourceAPI
      params { use :community_name }
    end
  end
end
