require 'entities/json_context'
require 'policies/json_context_policy'

module API
  module V1
    # Json contexts API endpoints
    class JsonContexts < Grape::API
      helpers SharedHelpers

      before do
        authenticate!
      end

      resources :json_contexts do # rubocop:todo Metrics/BlockLength
        desc 'Retrieves all JSON contexts'
        get do
          authorize JsonContext, :index?
          present JsonContext.order(updated_at: :desc), with: Entities::JsonContext
        end

        desc 'Retrives a JSON context by its URL'
        params do
          requires :url, type: String, desc: 'Context URL'
        end
        get ':url', requirements: { url: /(.*)/i } do
          authorize JsonContext, :index?
          json_context = JsonContext.find_by!(url: params[:url])
          present json_context, with: Entities::JsonContext
        end

        desc 'Uploads a JSON context'
        params do
          requires :context, type: Hash, desc: 'Context payload'
          requires :url, type: String, desc: 'Context URL'
        end
        post do
          authorize JsonContext, :create?
          json_context = JsonContext.find_or_initialize_by(url: params[:url])
          status json_context.new_record? ? :created : :ok
          json_context.update!(context: params[:context])
          present json_context, with: Entities::JsonContext
        end
      end
    end
  end
end
