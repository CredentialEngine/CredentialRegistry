require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'helpers/shared_helpers'
require 'v1/envelope_helpers'
require 'v1/single_envelope'
require 'v1/versions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers EnvelopeHelpers

      params { use :envelope_community }
      before_validation { normalize_envelope_community }

      desc 'Show metadata community'
      get { EnvelopeCommunity.find_by(name: community).as_json }

      desc 'Gives general info about the community'
      get :info do
        comm = EnvelopeCommunity.find_by!(name: community)
        {
          total_envelopes: comm.envelopes.count,
          backup_item: comm.backup_item
        }
      end

      resource :envelopes do
        desc 'Retrieves all envelopes ordered by date', is_array: true
        params { use :pagination }
        paginate max_per_page: 200
        get do
          envelopes = paginate(Envelope.in_community(community).ordered_by_date)
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
          optional :update_if_exists,
                   type: Grape::API::Boolean,
                   desc: 'Whether to update the envelope if it already exists',
                   documentation: { param_type: 'query' }
        end
        post do
          envelope, errors = EnvelopeBuilder.new(
            params, update_if_exists: update_if_exists?
          ).build

          if errors
            json_error! errors, [:envelope, envelope.try(:resource_schema_name)]

          else
            present envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          end
        end

        desc 'Marks envelopes matching a resource locator as deleted'
        helpers do
          def validate_delete_envelope_json
            validator = JSONSchemaValidator.new(params, :delete_envelope)
            if validator.invalid?
              json_error! validator.error_messages, :delete_envelope
            end
          end

          def find_community_envelopes
            envelopes = Envelope.in_community(community)
                                .where(envelope_id: params[:envelope_id])
            if envelopes.empty?
              err = ['No matching envelopes found']
              json_error! err, :delete_envelope, :not_found
            end
            envelopes
          end
        end
        put do
          validate_delete_envelope_json
          envelopes = find_community_envelopes
          BatchDeleteEnvelopes.new(envelopes, DeleteToken.new(params)).run!

          body false
          status :no_content
        end

        desc 'Gives general info about the envelopes'
        get(:info) { envelopes_info }

        route_param :envelope_id do
          after_validation do
            @envelope = Envelope.in_community(community)
                                .find_by(envelope_id: params[:envelope_id])
            if @envelope.nil?
              error!({ errors: ['Couldn\'t find Envelope'] }, 404)
            end
          end

          mount API::V1::SingleEnvelope
          mount API::V1::Versions
        end
      end
    end
  end
end
