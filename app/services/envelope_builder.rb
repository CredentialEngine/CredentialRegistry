# responsible for build and doing the multi-step validations on envelopes
class EnvelopeBuilder
  attr_reader :params, :envelope, :errors

  def initialize(params, update_if_exists: false)
    @params = params
    @update_if_exists = update_if_exists
  end

  def build
    validate
    [envelope, errors]
  end

  def validate
    validate_json_schema && validate_model
    valid?
  end

  private

  def validate_json_schema
    validator = EnvelopeSchemaValidator.new params
    validator.validate
    errors_set validator.errors
    valid?
  end

  def validate_model
    envelope = existing_or_new_envelope
    envelope.validate
    errors_set envelope.errors.full_messages
    valid?
  end

  def errors_set(errs)
    @errors = errs.empty? ? nil : errs
  end

  def valid?
    @errors.nil? || @errors.try(:empty?)
  end

  def update_if_exists?
    @update_if_exists
  end

  def existing_or_new_envelope
    envelope = if update_if_exists?
                 Envelope.find_or_initialize_by(
                   envelope_id: params[:envelope_id]
                 )
               else
                 Envelope.new
               end

    envelope.assign_community(params.delete(:envelope_community))
    envelope.assign_attributes(params)
    @envelope = envelope
  end
end
