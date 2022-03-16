require 'publish_envelope_job'

# Schedules publishing for an envelope
class PublishRequest < ActiveRecord::Base
  belongs_to :envelope, optional: true

  scope :failed, -> { where.not(error: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :succeeded, -> { where(error: nil).where.not(completed_at: nil) }

  # Valid params:
  #   envelope_community_id
  #   organization_id
  #   user_id
  #   skip_validation
  #   envelope_id
  #   raw_resource
  #   publishing_organization_id
  #   resource_publish_type
  #   secondary_token
  def self.schedule(**params)
    publish_request = create!(request_params: params.to_json)
    PublishEnvelopeJob.perform_later(publish_request.id)
    publish_request
  end

  def complete(envelope_id)
    update(envelope_id: envelope_id, completed_at: Time.now)
  end

  def fail(error)
    update(error: error, completed_at: Time.now)
  end

  def to_params
    JSON.parse(request_params).deep_symbolize_keys
  end

  def failed?
    error.present?
  end

  def succeeded?
    completed_at.present? && error.blank?
  end

  def status
    if failed?
      'failed'
    elsif succeeded?
      'succeeded'
    else
      'pending'
    end
  end
end
