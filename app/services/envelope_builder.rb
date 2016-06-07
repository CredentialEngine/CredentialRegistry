# responsible for build and doing the multi-step validations on envelopes
class EnvelopeBuilder
  attr_reader :params, :envelope, :errors

  # params:
  #   - params: [Hash] containing the envelope attributes
  #   - update_if_exists: [Bool] tells if we should update or create a new obj
  def initialize(params, envelope: nil, update_if_exists: false)
    @params = params.slice(*allowed_params).with_indifferent_access
    @envelope = envelope
    @update_if_exists = update_if_exists
  end

  # validate and build the envelope
  # return:
  #   - [List] containing [envelope, errors]
  #
  #   e.g:
  #      envelope, errors = EnvelopeBuilder.new(params).build
  #
  def build
    validate
    envelope.save if valid?
    [envelope, errors]
  end

  # run all validations:
  #   - envelope json schema
  #   - active record model
  #   - resource json schema (encapsulated on the AR model validations)
  def validate
    validate_json_schema && validate_model
    valid?
  end

  def self.allowed_params
    @allowed_params ||= begin
      Envelope.column_names.map(&:to_sym) + [:envelope_community]
    end
  end

  def allowed_params
    self.class.allowed_params
  end

  private

  def validate_json_schema
    validator = EnvelopeSchemaValidator.new params
    validator.validate
    errors_set validator.errors.try(:values)
    valid?
  end

  def validate_model
    envelope = build_envelope
    envelope.validate
    errors_set envelope.errors.full_messages
    valid?
  end

  def errors_set(errs)
    @errors = (errs.nil? || errs.empty?) ? nil : errs
  end

  def valid?
    @errors.nil? || @errors.try(:empty?)
  end

  def update_if_exists?
    @update_if_exists
  end

  def build_envelope
    @envelope ||= existing_or_new_envelope
    @envelope.assign_community(params.delete(:envelope_community))
    @envelope.assign_attributes(params)
    @envelope
  end

  def existing_or_new_envelope
    if update_if_exists?
      Envelope.find_or_initialize_by(
        envelope_id: params[:envelope_id]
      )
    else
      Envelope.new
    end
  end
end
