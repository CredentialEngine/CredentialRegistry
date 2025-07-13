require 'entities/envelope_community'
require 'envelope_community'
require 'helpers/shared_helpers'
require 'policies/envelope_community_policy'

module API
  module V1
    # Envelope communities
    class EnvelopeCommunities < Grape::API
      helpers CommunityHelpers
      helpers SharedHelpers

      resources :envelope_communities do
        before do
          authenticate!
        end

        desc 'Create an envelope community'
        params do
          requires :name, type: String, desc: 'Envelope community name'
          optional :default, type: Boolean
          optional :secured, type: Boolean
          optional :secured_search, type: Boolean
        end
        post do
          community = EnvelopeCommunity.find_or_initialize_by(name: params[:name])
          authorize community, :create?
          community.update!(params.slice('default', 'secured', 'secured_search'))
          present community, with: API::Entities::EnvelopeCommunity
          status :created
        end
      end
    end
  end
end
