require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishInteractor < BaseInteractor
  attr_reader :envelope, :organization, :params, :publisher, :secondary_publisher

  def call(params)
    @envelope = params[:envelope]
    @organization = params[:organization]
    @params = params
    @publisher = params[:current_user].publisher
    @secondary_publisher = Publisher.find_by_token(params[:secondary_token])

    return unless authorized?(publisher, organization)

    @envelope, builder_errors = EnvelopeBuilder.new(
      envelope_attributes,
      skip_validation: params[:skip_validation], 
      update_if_exists: envelope.present?
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
      Publisher::NOT_AUTHORIZED_TO_PUBLISH,
      401
    ]

    false
  end

  def encoded_resource
    JWT.encode(
      resource,
      OpenSSL::PKey::RSA.new(key_pair.private_key),
      'RS256'
    )
  end

  def envelope_attributes
    main_resource = resource['@graph']&.first || {}

    {
      'envelope_id': envelope&.envelope_id,
      'envelope_ceterms_ctid': main_resource['ceterms:ctid']&.downcase,
      'envelope_ctdl_type': main_resource['@type'],
      'envelope_type': 'resource_data',
      'envelope_version': '1.0.0',
      'envelope_community': params[:envelope_community],
      'resource': encoded_resource,
      'resource_format': 'json',
      'resource_encoding': 'jwt',
      'resource_public_key': key_pair.public_key,
      'organization_id': organization.id,
      'publisher_id': publisher.id,
      'secondary_publisher_id': secondary_publisher&.id
    }
  end

  def key_pair
    organization.key_pair
  end

  def resource
    @resource ||=
      if envelope
        envelope.processed_resource
      else
        JSON.parse(params[:raw_resource])
      end
  end
end
