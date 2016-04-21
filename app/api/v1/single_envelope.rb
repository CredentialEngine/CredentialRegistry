module API
  module V1
    # Implements all the endpoints related to a single envelope
    class SingleEnvelope < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      desc 'Retrieves an envelope by identifier',
           entity: API::Entities::Envelope
      get do
        present @envelope, with: API::Entities::Envelope
      end

      desc 'Updates an existing envelope',
           http_codes: [{ code: 204, message: 'Envelope updated' }]
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

      desc 'Marks an existing envelope as deleted'
      params do
        requires :resource_public_key,
                 type: String,
                 desc: 'The original public key that created the envelope'
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
    end
  end
end
