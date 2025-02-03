require 'extract_envelope_resources_job'

# responsible for build and doing the multi-step validations on envelopes
class EnvelopeBuilder
  attr_reader :params, :envelope, :envelope_community, :errors

  # Params:
  #   - params: [Hash] containing the envelope attributes
  #   - update_if_exists: [Bool] tells if we should update or create a new obj
  def initialize(params, envelope: nil, update_if_exists: false,
                 skip_validation: false)
    @params = sanitize(params)
    @envelope = envelope
    @update_if_exists = update_if_exists
    @skip_validation = skip_validation
    @envelope_community = @params[:envelope_community]
  end

  # Validate and build the envelope
  #
  # Return: [List] containing [envelope, errors]
  #
  # Example:
  #   envelope, errors = EnvelopeBuilder.new(params).build
  def build
    validate

    if envelope&.changed?
      was_saved = envelope.save if valid?
      ExtractEnvelopeResourcesJob.perform_later(envelope.id) if was_saved
    end

    [envelope, errors]
  end

  # Run all validations:
  #   - envelope json schema
  #   - ActiveRecord model
  #   - resource json schema (encapsulated on the AR model validations)
  #
  # Return: [Boolean]
  def validate
    validate_envelope
    if valid?
      build_envelope
      validate_model
    end
    valid?
  end

  # List of allowed params to be passed on the Envelope construction
  #
  # Return: [List[Symbol]] list of field names
  def self.allowed_params
    @allowed_params ||= Envelope.column_names.map(&:to_sym) # + [:envelope_community]
  end

  def allowed_params
    self.class.allowed_params
  end

  private

  def validate_envelope
    validator = JSONSchemaValidator.new params, :envelope
    validator.validate
    errors_set validator.error_messages
    valid?
  end

  def validate_model
    envelope.validate
    errors_set envelope.errors.full_messages
    valid?
  end

  def errors_set(errs)
    @errors = errs.nil? || errs.empty? ? nil : errs
  end

  def valid?
    @errors.nil? || @errors.try(:empty?)
  end

  def update_if_exists?
    @update_if_exists
  end

  def skip_validation?
    @skip_validation && @envelope.envelope_community.skip_validation_enabled?
  end

  def build_envelope
    @envelope ||= existing_or_new_envelope
    @envelope.assign_community(envelope_community)
    @envelope.assign_attributes(params.slice(*allowed_params))
    @envelope.skip_validation = true if skip_validation?
    @envelope
  end

  # rubocop:disable Metrics/AbcSize
  def existing_or_new_envelope # rubocop:todo Metrics/MethodLength
    envelope = if update_if_exists?
                 Envelope.find_or_initialize_by(envelope_id: params[:envelope_id])
               else
                 Envelope.new
               end
    return envelope if envelope.persisted?

    envelope.assign_community(envelope_community)
    envelope.assign_attributes(params.slice(*allowed_params))
    envelope.process_resource

    Envelope
      .not_deleted
      .where(organization_id: params[:organization_id])
      .community_resource(
        envelope_community,
        envelope.processed_resource_ctid
      ) || envelope
  end
  # rubocop:enable Metrics/AbcSize

  def sanitize(params)
    params.with_indifferent_access.compact.delete_if { |_k, v| v.try(:blank?) }
  end
end
