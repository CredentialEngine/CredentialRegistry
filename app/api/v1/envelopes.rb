require 'mountable_api'
require 'envelope'
require 'delete_token'
require 'learning_registry_metadata'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'helpers/shared_params'
require 'v1/single_envelope'
require 'v1/versions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < MountableAPI
      mounted do
        include API::V1::Defaults

        helpers SharedParams

        params do
          use :envelope_community
        end

        before_validation do
          if params[:envelope_community].present?
            params[:envelope_community] = params[:envelope_community].underscore
          end
        end

        resource :envelopes do
          desc 'Retrieves all envelopes ordered by date', is_array: true
          params do
            use :pagination
          end
          paginate max_per_page: 200
          get do
            envelopes = paginate(
              Envelope.in_community(params[:envelope_community]).ordered_by_date
            )

            present envelopes, with: API::Entities::Envelope
          end

          desc 'Publishes a new envelope',
               http_codes: [
                 { code: 201, message: 'Envelope created' },
                 { code: 200, message: 'Envelope updated' }
               ]
          helpers do
            def update_if_exists?
              @update_if_exists ||= params.delete(:update_if_exists)
            end
          end
          params do
            use :publish_envelope
            optional :update_if_exists,
                     type: Grape::API::Boolean,
                     desc: 'Whether to update the envelope if it already '\
                           'exists',
                     documentation: { param_type: 'query' }
          end
          post do
            envelope, errors = EnvelopeBuilder.new(
              processed_params,
              update_if_exists: update_if_exists?
            ).build

            if errors
              error!({ errors: errors }, :unprocessable_entity)

            else
              present envelope, with: API::Entities::Envelope
              update_if_exists? ? status(:ok) : status(:created)
            end
          end

          desc 'Marks envelopes matching a resource locator as deleted',
               hidden: true
          params do
            use :delete_envelope
            requires :url,
                     type: String,
                     desc: 'The URL that envelopes must match to be deleted',
                     documentation: { param_type: 'body' }
          end
          delete do
            envelopes = Envelope.in_community(params[:envelope_community])
                                .with_url(params[:url])
            if envelopes.empty?
              error!({ errors: ['No matching envelopes found'] }, :not_found)
            end

            BatchDeleteEnvelopes.new(envelopes,
                                     DeleteToken.new(processed_params)).run!

            body false
            status :no_content
          end

          route_param :envelope_id do
            after_validation do
              @envelope = Envelope.in_community(params[:envelope_community])
                                  .find_by!(envelope_id: params[:envelope_id])
            end

            mount API::V1::SingleEnvelope.anonymous_class
            mount API::V1::Versions.anonymous_class
          end
        end
      end
    end
  end
end
