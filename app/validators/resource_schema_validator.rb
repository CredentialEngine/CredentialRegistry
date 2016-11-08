require 'json_schema_validator'

# Validates the encoded resource with the corresponding community schema-json
class ResourceSchemaValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    validator = JSONSchemaValidator.new(record.processed_resource,
                                        record.resource_schema_name)

    validator.validate

    if validator.errors.try(:any?)
      errors = validator.error_messages
      record.errors.add :resource, "JSON Schema validation errors: #{errors}"
    end
  end
end
