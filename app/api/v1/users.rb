require 'entities/user'
require 'helpers/shared_helpers'
require 'policies/user_policy'
require 'user'

module API
  module V1
    # User API endpoint
    class Users < Grape::API
      helpers CommunityHelpers
      helpers SharedHelpers

      resources :users do
        desc 'Creates a new user for a given publisher'
        before do
          authenticate!
        end
        params do
          requires :email, type: String, desc: 'User email'
        end
        post do
          authorize User, :create?
          current_user.admin.publishers.find(params[:publisher_id])
          user = User.create!(params)
          present user, with: API::Entities::User
        end
      end
    end
  end
end
