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

    unless authorized?
      @error = [
        Publisher::NOT_AUTHORIZED_TO_PUBLISH,
        401
      ]
      return
    end

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
  # rubocop:enable Metrics/MethodLength

  private

  def authorized?
    return false unless publisher.authorized_to_publish?(organization)
    return true if publishing_organization.nil?

    publisher.authorized_to_publish?(publishing_organization)
  end

  # rubocop:todo Metrics/MethodLength
  def envelope_attributes # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    main_resource = resource['@graph']&.first || {}

    {
      envelope_id: envelope&.envelope_id,
      envelope_ceterms_ctid: main_resource['ceterms:ctid']&.downcase,
      envelope_ctdl_type: main_resource['@type'],
      envelope_type: 'resource_data',
      envelope_version: '1.0.0',
      envelope_community: params[:envelope_community],
      resource_format: 'json',
      resource_encoding: 'jwt',
      organization_id: organization.id,
      processed_resource: resource,
      publishing_organization_id: publishing_organization&.id,
      resource_publish_type: resource_publish_type,
      publisher_id: publisher.id,
      secondary_publisher_id: secondary_publisher&.id
    }
  end
  # rubocop:enable Metrics/MethodLength

  def resource
    @resource ||=
      if envelope
        envelope.processed_resource
      else
        JSON.parse(params[:raw_resource])
      end
  end
end
