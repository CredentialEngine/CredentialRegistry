module API
  module V1
    # Implements all the endpoints related to a single envelope
    class SingleEnvelope < MountableAPI
      mounted do
        include API::V1::Defaults

        helpers SharedParams

        desc 'Retrieves an envelope by identifier',
             entity: API::Entities::Envelope
        params do
          use :envelope_community
          use :envelope_id
        end
        get do
          present @envelope, with: API::Entities::Envelope
        end

        desc 'Updates an existing envelope'
        params do
          use :envelope_community
          use :envelope_id
        end
        patch do
          envelope, errors = EnvelopeBuilder.new(
            params,
            envelope: @envelope
          ).build

          if errors
            error!({ errors: errors }, :unprocessable_entity)

          else
            present envelope, with: API::Entities::Envelope
          end
        end

        desc 'Marks an existing envelope as deleted'
        params do
          use :envelope_community
          use :envelope_id
          use :delete_envelope
        end
        delete do
          BatchDeleteEnvelopes.new(Array(@envelope),
                                   DeleteToken.new(processed_params)).run!

          body false
          status :no_content
        end
      end
    end
  end
end
