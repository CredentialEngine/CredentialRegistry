require 'extract_envelope_resources'

class PublishEnvelopeJob < ActiveJob::Base
  def perform(publish_request_id)
    ActiveRecord::Base.transaction do
      publish_request = PublishRequest.find(publish_request_id)
      publish_args = build_args(publish_request.to_params)
      publish_result = PublishInteractor.call(**publish_args)

      if publish_result.success?
        publish_request.complete(publish_result.envelope.id)
      else
        publish_request.fail(publish_result.error)
      end
    end
  end

  private

  def build_args(request_params)
    interactor_args = {
      envelope_community: request_params[:envelope_community],
      organization: Organization.find(request_params[:organization_id]),
      resource_publish_type: request_params[:resource_publish_type],
      current_user: User.find(request_params[:user_id]),
      skip_validation: request_params[:skip_validation]
    }

    if request_params.key?(:envelope_id)
      interactor_args[:envelope] = Envelope.find(request_params[:envelope_id])
    else
      interactor_args[:raw_resource] = request_params[:raw_resource]
    end

    interactor_args[:publishing_organization] = Organization.find(request_params[:publishing_organization_id]) \
      if request_params.key?(:publishing_organization_id)

    interactor_args[:secondary_token] = request_params[:secondary_token] if request_params.key?(:secondary_token)

    interactor_args
  end
end
