require 'envelope'
require 'learning_registry_metadata'
require 'batch_delete_envelopes'
require 'entities/envelope'
require 'helpers/shared_params'
require 'v1/single_envelope'
require 'v1/versions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :envelopes do
        desc 'Retrieves all envelopes ordered by date',
             is_array: true
        params do
          use :pagination
        end
        get do
          envelopes = Envelope.ordered_by_date
                              .page(params[:page])
                              .per(params[:per_page])

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

          def existing_or_new_envelope
            envelope = if update_if_exists?
                         Envelope.find_or_initialize_by(
                           envelope_id: processed_params[:envelope_id]
                         )
                       else
                         Envelope.new
                       end

            envelope.assign_attributes(processed_params)
            envelope
          end
        end
        params do
          use :envelope
          optional :update_if_exists,
                   type: Boolean,
                   desc: 'Whether to update the envelope if it already exists',
                   documentation: { param_type: 'query' }
        end
        post do
          envelope = existing_or_new_envelope

          if envelope.save
            present envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          else
            error!({ errors: envelope.errors.full_messages },
                   :unprocessable_entity)
          end
        end

        desc 'Marks envelopes matching a resource locator as deleted'
        params do
          requires :resource_public_key,
                   type: String,
                   desc: 'The original public key that created the envelope'
          requires :url,
                   type: String,
                   desc: 'The URL that envelopes must match to be deleted'
        end
        delete do
          envelopes = Envelope.with_url(params[:url])
          if envelopes.empty?
            error!({ errors: ['No matching envelopes found'] }, :not_found)
          end

          BatchDeleteEnvelopes.new(envelopes, params[:resource_public_key]).run!

          body false
          status :no_content
        end

        route_param :envelope_id, desc: 'The envelope identifier' do
          before do
            @envelope = Envelope.find_by!(envelope_id: params[:envelope_id])
          end

          mount API::V1::SingleEnvelope
          mount API::V1::Versions
        end
      end
    end
  end
end
