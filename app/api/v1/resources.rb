module API
  module V1
    # Implements all the endpoints related to resources
    class Resources < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers
      helpers EnvelopeHelpers

      before_validation { normalize_envelope_community }

      helpers do
        def find_envelope
          @envelope = Envelope.where('processed_resource @> ?',
                                     { '@id' => params[:id] }.to_json)
                              .first

          if @envelope.blank?
            err = ['No matching resource found']
            json_error! err, nil, :not_found
          end
        end
      end

      resource :resources do
        desc 'Publishes a new envelope',
             http_codes: [
               { code: 201, message: 'Envelope created' },
               { code: 200, message: 'Envelope updated' }
             ]
        helpers do
          def update_if_exists?
            @update_if_exists ||= params.delete(:update_if_exists)
          end

          def skip?
            @skip_validation ||= params.delete(:skip_validation)
          end
        end
        params do
          optional :update_if_exists,
                   type: Grape::API::Boolean,
                   desc: 'Whether to update the envelope if it already exists',
                   documentation: { param_type: 'query' }
          optional :skip_validation,
                   type: Grape::API::Boolean,
                   desc: 'Whether to skip validations if the community allows',
                   documentation: { param_type: 'query' }
        end
        post do
          envelope, errors = EnvelopeBuilder.new(
            params, update_if_exists: update_if_exists?, skip_validation: skip?
          ).build

          if errors
            json_error! errors, [:envelope, envelope.try(:resource_schema_name)]

          else
            present envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          end
        end

        desc 'Return a resource.'
        params do
          requires :id, type: String, desc: 'Resource id.'
        end
        route_param :id do
          after_validation do
            find_envelope
          end
          get do
            present @envelope.processed_resource
          end
        end
      end
    end
  end
end
