require 'entities/envelope_community_config'
require 'entities/envelope_community_config_version'
require 'envelope_community_config'
require 'policies/envelope_community_config_policy'

module API
  module V1
    # Envelope community config API endpoints
    class Config < Grape::API
      helpers CommunityHelpers

      before do
        authenticate!
      end

      route_param :community_name do # rubocop:todo Metrics/BlockLength
        resources :config do # rubocop:todo Metrics/BlockLength
          desc "Returns the community's config"
          get do
            authorize EnvelopeCommunityConfig, :show?
            current_user_community.config
          end

          desc 'Sets a new config for the community'
          params do
            requires :description, type: String
            requires :payload, type: Hash
          end
          post do
            authorize EnvelopeCommunityConfig, :create?

            config = current_user_community.envelope_community_config ||
                     current_user_community.build_envelope_community_config

            if config.update(params.slice(:description, :payload))
              status :ok
              present config, with: Entities::EnvelopeCommunityConfig
            else
              status :unprocessable_entity
              { errors: config.errors.full_messages }
            end
          end

          resources :changes do
            desc 'Lists the changes to the config'
            get do
              authorize EnvelopeCommunityConfig, :show?

              if (config = current_user_community.envelope_community_config)
                present config.versions,
                        with: Entities::EnvelopeCommunityConfigVersion
              else
                []
              end
            end
          end
        end
      end
    end
  end
end
