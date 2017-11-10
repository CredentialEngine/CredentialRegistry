require 'entities/publisher'
require 'helpers/shared_helpers'
require 'policies/publisher_policy'
require 'publisher'
require 'v1/users'

module API
  module V1
    # Publisher API endpoints
    class Publishers < Grape::API
      helpers SharedHelpers

      resources :publishers do
        desc 'Returns all the publishers'
        get do
          present Publisher.order(:name), with: API::Entities::Publisher
        end

        desc 'Creates a new publisher'
        before do
          authenticate!
        end
        params do
          requires :name, type: String, desc: 'Publisher name'
          optional :contact_info, type: String, desc: 'Publisher contact info'
          optional :description, type: String, desc: 'Publisher descriptions'
        end
        post do
          authorize Publisher, :create?
          publisher = current_user.admin.publishers.create!(params)
          present publisher, with: API::Entities::Publisher
        end

        route_param :publisher_id do
          mount API::V1::Users
        end
      end
    end
  end
end
