require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishInteractor < BaseInteractor
  attr_reader :envelope

  NOT_AUTHORIZED_TO_PUBLISH =
    'Publisher is not authorized to publish on behalf of this organization'.freeze

  def call(params)
    organization = Organization.find(params[:organization_id])
    publisher = params[:current_user].publisher

    return unless authorized_to_publish?(organization, publisher)

    @envelope, builder_errors = EnvelopeBuilder.new(
      envelope_attributes(params.merge(organization: organization, publisher: publisher))
    ).build

    return unless builder_errors

    @error = [
      builder_errors,
      422
    ]
  end

  private

  def authorized_to_publish?(organization, publisher)
    authorized = OrganizationPublisher
                 .where(organization: organization)
                 .where(publisher: publisher)
                 .exists?

    # if the publisher is already authorized to publish on behalf of this
    # organization, great
    return true if authorized

    # if not, and the publisher is not a super publisher, bail
    unless publisher.super_publisher
      @error = [
        NOT_AUTHORIZED_TO_PUBLISH,
        401
      ]

      return false
    end

    # super publisher get an OrganizationPublisher record created on the fly,
    # authorizing them to publish on behalf of this organization now and in the
    # future
    OrganizationPublisher.create(organization: organization, publisher: publisher)

    true
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
      'publisher_id': params[:publisher].id
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
