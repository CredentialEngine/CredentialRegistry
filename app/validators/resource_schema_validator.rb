require 'json_schema_validator'

# Validates that the same public key is used when updating/deleting an envelope
class ResourceSchemaValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    validator = JSONSchemaValidator.new(record.processed_resource, schema_name)
    validator.validate

    if validator.errors.try(:any?)
      errors = validator.error_messages
      record.errors.add :resource, "JSON Schema validation errors: #{errors}"
    end
  end

  private

  def schema_name
    record.community_name
  end
end
