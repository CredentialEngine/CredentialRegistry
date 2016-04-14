require 'envelope'
require 'learning_registry_metadata'
require 'entities/envelope'
require 'helpers/shared_params'
require 'v1/versions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :envelopes do
        desc 'Retrieve all envelopes ordered by date'
        params do
          use :pagination
        end
        get do
          envelopes = Envelope.ordered_by_date
                              .page(params[:page])
                              .per(params[:per_page])

          present envelopes, with: API::Entities::Envelope
        end

        desc 'Publish a new envelope'
        params do
          use :envelope
        end
        post do
          envelope = Envelope.new(processed_params)

          if envelope.save
            body false
            status :created
          else
            error!({ errors: envelope.errors.full_messages },
                   :unprocessable_entity)
          end
        end

        route_param :envelope_id do
          before do
            @envelope = Envelope.find_by!(envelope_id: params[:envelope_id])
          end

          desc 'Retrieves an envelope by identifier'
          get do
            present @envelope, with: API::Entities::Envelope
          end

          desc 'Updates an existing envelope'
          params do
            use :envelope
          end
          patch do
            if @envelope.update_attributes(processed_params)
              body false
              status :no_content
            else
              error!({ errors: @envelope.errors.full_messages },
                     :unprocessable_entity)
            end
          end

          desc 'Mark an existing envelope as deleted'
          params do
            requires :resource_public_key, type: String
          end
          delete do
            @envelope.assign_attributes(processed_params)
            @envelope.deleted_at = Time.current

            if @envelope.save
              body false
              status :no_content
            else
              error!({ errors: @envelope.errors.full_messages },
                     :unprocessable_entity)
            end
          end

          mount API::V1::Versions
        end
      end
    end
  end
end
