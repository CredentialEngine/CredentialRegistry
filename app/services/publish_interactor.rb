require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishInteractor < BaseInteractor
  attr_reader :envelope

  def call(params)
    organization = Organization.find(params[:organization_id])
    publisher = params[:current_user].publisher

    organization_publisher = fetch_or_create_organization_publisher(organization, publisher)

    unless organization_publisher
      @error = [
        'User\'s publisher is not authorized to publish on behalf of this organization',
        401
      ]
      return
    end

    @envelope, builder_errors = EnvelopeBuilder.new(
      envelope_attributes(params.merge(organization_publisher: organization_publisher))
    ).build

    return unless builder_errors

    @error = [
      builder_errors,
      422
    ]
  end

  private

  def fetch_or_create_organization_publisher(organization, publisher)
    organization_publisher = OrganizationPublisher
                             .where(organization: organization)
                             .where(publisher: publisher)
                             .first

    # if the publisher is already authorized to publish on behalf of this
    # organization, great, use that OrganizationPublisher record
    return organization_publisher if organization_publisher

    # if not, and the publisher is not a super publisher, bail
    return nil unless publisher.super_publisher

    # super publisher get an OrganizationPublisher record created on the fly,
    # authorizing them to publish on behalf of this organization now and in the
    # future
    OrganizationPublisher.create(organization: organization, publisher: publisher)
  end

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
      'organization_id': params[:organization_publisher].organization_id,
      'publisher_id': params[:organization_publisher].publisher_id
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
