require 'services/base_interactor'

# Publishes a resource on behalf of an organization
class PublishInteractor < BaseInteractor
  attr_reader :envelope, :organization, :params, :publishing_organization, :resource_publish_type,
              :publisher, :secondary_publisher

  # rubocop:todo Metrics/MethodLength
  def call(params) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @envelope = params[:envelope]
    @organization = params[:organization]
    @params = params
    @publishing_organization = params[:publishing_organization]
    @resource_publish_type = params[:resource_publish_type] || 'primary'
    @publisher = params[:current_user].publisher
    @secondary_publisher = Publisher.find_by_token(params[:secondary_token])

    if payload_errors
      @error = [payload_errors, 422]
      return
    end

    @envelope, builder_errors = EnvelopeBuilder.new(
      envelope_attributes,
      envelope:,
      skip_validation: params[:skip_validation],
      update_if_exists: envelope.present?
    ).build

    return unless builder_errors

    @error = [
      builder_errors,
      422
    ]
  end
  # rubocop:enable Metrics/MethodLength

  private

  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/CyclomaticComplexity
  def envelope_attributes # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @envelope_attributes ||= begin
      main_resource = resource['@graph']&.first || {}

      attrs = {
        envelope_ceterms_ctid: main_resource['ceterms:ctid']&.downcase,
        envelope_community: params[:envelope_community],
        envelope_ctdl_type: main_resource['@type'],
        envelope_type: 'resource_data',
        envelope_version: '1.0.0',
        organization_id: organization.id,
        processed_resource: resource,
        publisher_id: publisher.id,
        publishing_organization_id: publishing_organization&.id,
        resource: nil,
        resource_encoding: 'jwt',
        resource_format: 'json',
        resource_public_key: nil,
        resource_publish_type: resource_publish_type,
        secondary_publisher_id: secondary_publisher&.id
      }

      attrs.merge(envelope_id: envelope.envelope_id) if envelope
      attrs
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  def payload_errors
    @payload_errors ||= begin
      validator = JSONSchemaValidator.new(resource, :publish_envelope)
      validator.validate
      validator.errors
    end
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
