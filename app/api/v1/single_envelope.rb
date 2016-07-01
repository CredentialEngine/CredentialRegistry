module API
  module V1
    # Implements all the endpoints related to a single envelope
    class SingleEnvelope < Grape::API
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
          json_error! errors, [:envelope, envelope.try(:community_name)]

        else
          present envelope, with: API::Entities::Envelope
        end
      end

      desc 'Marks an existing envelope as deleted'
      params do
        use :envelope_community
        use :envelope_id
      end
      delete do
        validator = JSONSchemaValidator.new(params, :delete_envelope)
        if validator.invalid?
          json_error! validator.error_messages, :delete_envelope
        end

        BatchDeleteEnvelopes.new(Array(@envelope),
                                 DeleteToken.new(params)).run!

        body false
        status :no_content
      end
    end
  end
end
