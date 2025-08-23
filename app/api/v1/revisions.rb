require 'envelope'
require 'entities/envelope'
require 'helpers/shared_helpers'

module API
  module V1
    # Implements all the endpoints related to envelope revisions
    module Revisions
      # rubocop:todo Lint/MissingCopEnableDirective
      # rubocop:disable Metrics/MethodLength
      # rubocop:enable Lint/MissingCopEnableDirective
      def self.included(base)
        base.instance_eval do
          helpers SharedHelpers

          resource :revisions do
            route_param :revision_id, desc: 'The revision identifier' do
              desc 'Retrieves a specific envelope version',
                   entity: API::Entities::Envelope
              params do
                use :envelope_community
                use :envelope_id
                requires :revision_id, desc: 'Unique revision identifier'
              end
              get do
                envelope = @envelope.versions.find(params[:revision_id]).reify

                present envelope, with: API::Entities::Envelope, is_version: true
              end
            end
          end
        end
      end
    end
  end
end
