require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishOnBehalfInteractor < BaseInteractor
  attr_reader :builder_envelope, :builder_errors

  def call(params)
    organization = Organization.find(params[:organization_id])
    publisher = params[:current_user].publisher
    organization_publisher = OrganizationPublisher
                             .where(organization: organization)
                             .where(publisher: publisher)
                             .first

    unless organization_publisher
      @error = [
        'User\'s publisher is not authorized to publish on behalf of this organization',
        401
      ]
      return
    end

    @builder_envelope, @builder_errors = EnvelopeBuilder.new(
      envelope_attributes(params.merge(organization_publisher: organization_publisher))
    ).build
  end

  private

  def envelope_attributes(params)
    key_pair = params[:organization_publisher].key_pair

    {
      'envelope_type': 'resource_data',
      'envelope_version': '1.0.0',
      'envelope_community': params[:envelope_community],
      'resource': encode(params[:raw_resource], key_pair.private_key),
      'resource_format': 'json',
      'resource_encoding': 'jwt',
      'resource_public_key': key_pair.public_key,
      'organization_id': params[:organization_publisher].organization.id,
      'publisher_id': params[:organization_publisher].publisher.id
    }
  end

  def encode(raw_resource, private_key)
    JWT.encode(
      JSON.parse(raw_resource),
      OpenSSL::PKey::RSA.new(private_key),
      'RS256'
    )
  end
end
