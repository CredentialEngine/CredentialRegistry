require 'entities/publish_request'
require 'helpers/shared_helpers'
require 'publish_request'

module API
  module V2
    # Publish requests API endpoints
    class PublishRequests < MountableAPI
      mounted do
        helpers SharedHelpers

        resources :publish_requests do
          desc 'Returns all the publish requests'
          before do
            authenticate!
          end
          params do
            use :pagination
          end
          paginate max_per_page: 200
          get do
            publish_requests = paginate PublishRequest.order(created_at: :desc)
            present publish_requests, with: API::Entities::PublishRequest
          end

          desc 'Return a publish request by ID'
          before do
            authenticate!
          end
          get ':id', requirements: { id: /(.*)/ } do
            publish_request = PublishRequest.find(params[:id])
            present publish_request, with: API::Entities::PublishRequest
          end
        end
      end
    end
  end
end
