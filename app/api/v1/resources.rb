module API
  module V1
    # Implements all the endpoints related to resources
    class Resources < Grape::API
      include API::V1::ResourceAPI
    end
  end
end
