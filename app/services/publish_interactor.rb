require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishInteractor < BaseInteractor
  attr_reader :envelope

  NOT_AUTHORIZED_TO_PUBLISH =
    'Publisher is not authorized to publish on behalf of this organization'.freeze

  def call(params)
    organization = Organization.find(params[:organization_id])
    publisher = params[:current_user].publisher

    return unless authorized?(publisher, organization)

    attributes =
      params.merge(organization: organization,
                   publisher: publisher,
                   secondary_publisher: Publisher.find_by_token(params[:secondary_token]))

    @envelope, builder_errors = EnvelopeBuilder.new(
      envelope_attributes(attributes)
    ).build

    return unless builder_errors

    @error = [
      builder_errors,
      422
    ]
  end

  private

  def authorized?(publisher, organization)
    return true if publisher.authorized_to_publish?(organization)

    @error = [
      NOT_AUTHORIZED_TO_PUBLISH,
      401
    ]

    false
  end

  def envelope_attributes(params)
    key_pair = params[:organization].key_pair

    {
      'envelope_type': 'resource_data',
      'envelope_version': '1.0.0',
      'envelope_community': params[:envelope_community],
      'resource': encode(params[:raw_resource], key_pair.private_key),
      'resource_format': 'json',
      'resource_encoding': 'jwt',
      'resource_public_key': key_pair.public_key,
      'organization_id': params[:organization].id,
      'publisher_id': params[:publisher].id,
      'secondary_publisher_id': params[:secondary_publisher]&.id
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
