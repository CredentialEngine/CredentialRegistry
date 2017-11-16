module API
  module V1
    # Default options for all API endpoints and versions
    module ResourcesPob
      extend ActiveSupport::Concern

      included do
        desc 'Takes a resource and an organization id, signs the resource '\
             'on behalf of an organization, and publishes a new envelope with '\
             'that signed resource',
             http_codes: [
               { code: 201, message: 'Envelope created' },
               { code: 200, message: 'Envelope updated' }
             ]

        params do
          use :update_if_exists
          use :skip_validation
        end

        # rubocop:disable Metrics/BlockLength
        post 'organizations/:organization_id/documents' do
          authenticate!
          params[:envelope_community] = select_community

          organization = Organization.find(params[:organization_id])
          publisher = current_user.publisher
          organization_publisher = OrganizationPublisher
                                   .where(organization: organization)
                                   .where(publisher: publisher)
                                   .first

          unless organization_publisher
            error!(
              'User\'s publisher is not authorized to publish on behalf of this organization',
              422
            )
          end

          key_pair = organization_publisher.key_pairs.first

          envelope_attributes = {
            'envelope_type': 'resource_data',
            'envelope_version': '1.0.0',
            'envelope_community': 'ce_registry',
            'resource': JWT.encode(
              env['api.request.body'],
              OpenSSL::PKey::RSA.new(key_pair.private_key),
              'RS256'
            ),
            'resource_format': 'json',
            'resource_encoding': 'jwt',
            'resource_public_key': key_pair.public_key
          }

          envelope, errors = EnvelopeBuilder.new(envelope_attributes).build

          if errors
            json_error! errors, [:envelope, envelope.try(:resource_schema_name)]
          else
            present envelope, with: API::Entities::Envelope
            update_if_exists? ? status(:ok) : status(:created)
          end
        end
      end
    end
  end
end
